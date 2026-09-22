# DPN Azure Reference Infrastructure

This repository is a portable OpenTofu/Terraform + Bicep reference implementation of a **Data Preparation Node (DPN)** - the participant-owned Azure infrastructure that hosts an application workload (typically running on AKS) with private networking, customer-managed key encryption, and centralized observability throughout.

It is designed so that any customer can deploy their own DPN into their own Azure subscription and tenant, via GitHub Actions or Azure DevOps, without depending on the original implementer.

## What gets deployed

```
                                     Private DNS Zones (shared/central)
                                     privatelink.vaultcore.azure.net
                                     privatelink.blob.core.windows.net
                                     privatelink.azurecr.io, ...

┌─────────────────────────── Your DPN subscription ───────────────────────────┐
│                                                                                │
│  Log Analytics   Azure Monitor       Microsoft Entra (Azure AD)             │
│                                                                                │
│  ┌─ Subnet ─────────────┐   ┌─ Subnet ───────────────────────────────────┐  │
│  │ Bring-your-own LB     │   │              AKS (private cluster)         │  │
│  │ (ingress)             │──▶│  system node pool | workload node pool     │  │
│  └───────────────────────┘   │  ingress controller, your application      │  │
│  ┌─ Subnet ─────────────┐   └─────────────────────────────────────────────┘  │
│  │ Bring-your-own        │                        │                          │
│  │ firewall (egress)     │                        ▼                          │
│  └───────────────────────┘   ┌─ Subnet: Private Endpoints ───────────────┐  │
│  ┌─ Subnet ─────────────┐   │ Storage │ Key Vault │ ACR │ Event Grid │   │  │
│  │ Jumpbox (Bastion)     │   │ Service Bus                             │  │
│  └───────────────────────┘   └────────────────────────────────────────────┘  │
│                                                                                │
└────────────────────────────────────────────────────────────────────────────────┘
```

Everything above (except the two "bring-your-own" boxes and the shared Private DNS Zones) is created by this codebase. Networking, Key Vault, ACR, and AKS form the backbone; the remaining modules (storage, Event Grid, Service Bus) exist to support the specific application pattern described below, and are only useful if your workload needs them.

## Repository layout

| Path | What it is |
|------|------------|
| `docs/` | Start here to deploy: prerequisites, step-by-step deployment guide, and what's been tested. |
| `dpn-azure-infrastructure/` | The root OpenTofu configuration - wires every module together. `environments/dpn_infrastructure.tfvars` is the example file you edit directly with your own values - the pipelines reference it by this exact path. |
| `modules/` | Reusable Terraform modules, one per Azure service. See the table below and each module's own README. |
| `dpn-azure-infrastructure/bootstrap/` | Bicep templates to create the OpenTofu remote-state backend (storage account + private endpoint) before the first `tofu init`. |
| `permissions/` | Bicep template + instructions to create the CI/CD deploy identity in your subscription. Run once per environment before bootstrap. |
| `.github/workflows/` | GitHub Actions pipelines: bootstrap, deploy, destroy (see each file's header comment for required secrets/variables). |
| `azure-pipelines/` | The same four pipelines for Azure DevOps. |
| `.checkov.yaml`, `.trivyignore`, `.tflint.hcl` | Optional security/quality scanner configs. Not run automatically by the pipelines - install the tools yourself and point them at these configs if you want them. |

## Modules and why they exist

| Module | Purpose in this architecture |
|--------|-------------------------------|
| `networking` | Creates subnets (and their NSGs) in your **existing** VNet. Every other module's private endpoint lands in a subnet this module creates. This repo does not create the VNet itself - that's assumed to already exist as shared platform infrastructure. Also wires an empty route table (UDR) to the `aks` subnet - add your firewall/NVA as its default route yourself, see the `route_table` example on the `aks` subnet in `environments/dpn_infrastructure.tfvars`. |
| `keyvault` | Central secrets/keys store. Holds the customer-managed key (CMK) used to encrypt every other resource that supports it, plus any application secrets. Every workload identity in this architecture is granted access here, not given its own key management. |
| `container_registry` | Private Azure Container Registry for your application's container images. AKS's cluster and kubelet identities are automatically granted pull access. |
| `aks` | The compute layer - a private AKS cluster that runs your application. Comes with a system node pool (AKS-managed components only) and an optional workload node pool (your containers), Key Vault CSI driver for secret injection, and workload identity federation. |
| `workload_identity` | Lets a specific Kubernetes pod (via its ServiceAccount) authenticate directly to Key Vault with no stored credential, using AKS's OIDC issuer. This is how your application running in AKS is meant to reach secrets in `keyvault`. |
| `loganalytics` | Central Log Analytics workspace. Every module's diagnostic settings point here. |
| `bastion` + `vm` | One of two admin-access paths (your choice - see `bastion_enabled` in `dpn_infrastructure.tfvars`): a Windows jump host (`vm`, always deployed) reachable through Azure Bastion (`bastion`, optional). The alternative is an existing AVD (Azure Virtual Desktop) desktop with private network line of sight into this VNet, which needs neither module. Platform engineers use whichever path is enabled to reach the private AKS API server and other private-endpoint-only resources for day-to-day operations. |
| `event_grid`, `service_bus`, `storage` | Support a specific application pattern - see "File-scanning pattern" below. Skip these three entirely if your workload doesn't need it. |

## File-scanning pattern (event_grid + service_bus + storage)

`event_grid`, `service_bus`, and two of the three `storage` deployments (`file_scanning_storage`, and whatever storage account your application treats as the destination) exist to support a specific, common pattern for this kind of platform: **files land in a storage account, get scanned for malware before anything trusts them, and only clean files continue downstream.**

The intended flow:

1. A file is uploaded to the storage account that plays the "landing zone" role (`file_scanning_storage` in this codebase).
2. **Microsoft Defender for Storage** (a subscription/storage-account-level setting, not something this Terraform config enables - turn it on separately in Defender for Cloud) scans the blob and publishes a malware-scan-result event.
3. That event is delivered to the `event_grid` custom topic.
4. An event subscription (not included in this codebase - see below) forwards the event to the `service_bus` topic/queue for reliable, decoupled processing.
5. A consumer application (an Azure Function, a container in AKS, or any service you run - **not something this codebase provides**) reads the Service Bus message, checks the scan verdict, and if the file is clean, copies/moves it from the landing-zone storage account to its real destination.

**Important - a real Azure platform limitation, not a bug in this code:** Microsoft Defender for Storage cannot deliver its scan-result events to an Event Grid topic that only accepts traffic on a private endpoint. If `event_grid` is wired to receive Defender for Storage events, `public_network_access_enabled` on that topic **must stay `true`**, even though this module also always deploys a private endpoint alongside it. This is confirmed by Microsoft's own documentation, not a misconfiguration - do not "fix" this by disabling public access, or scan results will silently stop arriving. See `modules/event_grid/README.md`.

> **Enterprise Azure Policy warning:** if your tenant enforces a "deny public network access" / "deny public endpoints" Azure Policy definition against Event Grid topics or storage accounts, it **will block this deployment** unless you pre-arrange a policy exemption for the `event_grid` topic before running `apply`. This is a genuine conflict between two legitimate requirements (your landing zone's policy vs. Defender for Storage's delivery requirement), not something this codebase can route around - raise it with whoever owns Azure Policy in your tenant before you deploy the file-scanning pattern, not after a failed pipeline run.

**What this codebase does NOT provide** for this pattern, and you will need to build yourself:
- The Event Grid event subscription connecting the storage account's Defender for Storage events to the `event_grid` topic (and from there to `service_bus`).
- The consumer application that reads from Service Bus and performs the actual file copy/move. Where it runs (an Azure Function, a pod on the `aks` cluster, etc.) and how it authenticates (workload identity, if running on AKS) is an application-level decision outside this reference architecture's scope.
- Enabling Microsoft Defender for Storage itself on the landing-zone storage account.

If your workload doesn't need file scanning, you can remove the `event_grid`, `service_bus`, and `file_scanning_storage` module blocks from `dpn-azure-infrastructure/main.tf` entirely.

## Requirements

Minimum tested/pinned tool versions - the pipelines install these exact versions automatically, so this table only matters if you're running commands locally:

| Tool | Version | Where it's pinned |
| --- | --- | --- |
| OpenTofu CLI | `1.9.0` | `required_version` in `dpn-azure-infrastructure/providers.tf`; installed by every pipeline job (`TOFU_VERSION`) |
| HashiCorp AzureRM provider | `4.56.0` (exact) | `required_providers` in `dpn-azure-infrastructure/providers.tf` |
| AKS Kubernetes version | `1.33` in the example `dpn_infrastructure.tfvars` (`aks_kubernetes_version`) | Not hardcoded - set to any version your subscription's AKS still supports |
| Bicep CLI | Whatever ships with your Azure CLI | Bootstrap/permissions templates deploy via `az deployment group create`, which uses Azure CLI's bundled Bicep - no separate Bicep CLI install or version pin exists in this repo |

## Getting started

1. **[docs/PREREQUISITES.md](docs/PREREQUISITES.md)** - Azure prerequisites, creating your deploy identity, and the exact secrets/variables your CI/CD platform (GitHub Actions or Azure DevOps) needs configured before anything will run.
2. **[docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)** - step-by-step: bootstrap, configure `dpn_infrastructure.tfvars`, plan, apply, verify, and (if you ever need it) destroy.
3. **[docs/TESTING_AND_VALIDATION.md](docs/TESTING_AND_VALIDATION.md)** - what's been statically verified about this codebase, and how to run the same checks yourself.
4. **[docs/SECURITY_AND_COMPLIANCE.md](docs/SECURITY_AND_COMPLIANCE.md)** - what security controls are implemented and how they relate to CIS/NIST, what isn't, and known gaps in the default configuration.

Once `apply` finishes, do a quick sanity check before trusting the deployment (full detail in [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) Step 6):

```bash
# From the jump host - reached via Azure Bastion in the Portal if bastion_enabled = true (see
# modules/bastion + modules/vm), or via your own AVD desktop if you're using that instead
az aks get-credentials --resource-group <your-aks-rg> --name <your-aks-name>
kubectl get nodes
```

## Scope, support, and things to know before you rely on this

**Provided as-is, no warranty, no support SLA.** This is a reference implementation, not a commercially supported product. There is no guarantee of fitness for any particular purpose, and no ongoing support commitment attached to it - review and test it against your own requirements before depending on it, the same as you would any other piece of code you didn't write yourself.

**Licensed, not public domain.** OpenTofu, Terraform, Bicep, and the CI/CD platforms this codebase runs on are all open source - but that does not make this codebase open source by default, and using open-source tooling grants no rights over the configuration written for it. See the [License](#license) section below for the exact terms this repository is released under. Not legal advice - confirm with whoever handles legal/IP at your organization before wide distribution.

**Single region, no built-in disaster recovery.** Every module deploys into one Azure region with locally-redundant storage (LRS) by default - there is no cross-region failover, no automated backup strategy, and no multi-region topology anywhere in this codebase. If your workload needs regional-outage durability, that's a design decision and implementation effort you need to add, not something toggled on here.

**This has real, ongoing Azure cost.** Several defaults use Premium-tier SKUs (Azure Container Registry Premium, Service Bus Premium) because they're required for private endpoints and customer-managed key encryption - these cost meaningfully more than Basic/Standard tiers. No cost estimate is provided anywhere in this repository, since actual cost depends on your region, usage, and any negotiated rates. Review the Azure Pricing Calculator against your specific `dpn_infrastructure.tfvars` configuration before deploying, especially before leaving anything running unattended.

**Assumes a landing zone already exists.** This codebase assumes you already have: an existing VNet with free address space, centrally-managed private DNS zones, and a self-hosted CI/CD runner with network access to that VNet (see [docs/PREREQUISITES.md](docs/PREREQUISITES.md)). It does not stand up a landing zone from nothing, and it has not been tested against every possible Azure tenant/subscription configuration - e.g. it assumes your chosen region supports Availability Zones, since AKS/ACR zone redundancy depend on that.

See [docs/SECURITY_AND_COMPLIANCE.md](docs/SECURITY_AND_COMPLIANCE.md) for the equivalent disclaimer specific to compliance/CIS/NIST claims.

## Public Funding Acknowledgment

This repository has been developed with public funding as part of the Data Sharing Infrastructure (DSI), a UK Government initiative. DSI, alongside its partners, has invested in this work to advance open, secure, and reusable digital twin technologies for any organisation, whether from the public or private sector, irrespective of size.

## License

This repository contains both source code and documentation, which are covered by different licenses:

- **Code:** Licensed under the [Apache License 2.0](./LICENSE.md).
- **Documentation:** Licensed under the [Open Government Licence v3.0 (OGL-UK-3.0)](./OGL_LICENSE.md).

By contributing to this repository, you agree that your contributions will be licenced under these terms.

## Security and Responsible Disclosure

We take security seriously. If you believe you have found a security vulnerability in this repository, please follow our responsible disclosure process outlined in [SECURITY.md](./SECURITY.md).

## Contributing

We welcome contributions that align with the Programme's objectives. See [CONTRIBUTING.md](./CONTRIBUTING.md) for the contribution model and [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) for expected behaviour.

## Acknowledgements

This repository has benefited from collaboration with various organisations. See [ACKNOWLEDGEMENTS.md](./ACKNOWLEDGEMENTS.md) for details.

## Maintainers and Release History

See [MAINTAINERS.md](./MAINTAINERS.md) for current repository maintainers and [CHANGELOG.md](./CHANGELOG.md) for release history.

## Support and Contact

For questions or support, check the repository [Issues](https://github.com/energy-dsi/dpn-infrastructure-azure/issues) or contact the DSI team at [dsi@neso.energy](mailto:dsi@neso.energy).

## Maintained by the National Energy System Operator (NESO)

Copyright 2026 NESO and the Crown. This work has been developed by NESO using content licensed by the Department for Business and Trade (UK) under the Open Government Licence v3.0 (OGL-UK-3.0). See [OGL_LICENSE.md](./OGL_LICENSE.md) for full terms.
