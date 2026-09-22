# Changelog

**Repository:** `dpn-infrastructure-azure`  
**Description:** `Tracks all notable changes, version history, and roadmap toward 1.0.0 following Semantic Versioning.`

<!-- SPDX-License-Identifier: OGL-UK-3.0 -->

--- 

All notable changes to this repository will be documented in this file.

This project follows **Semantic Versioning (SemVer)** ([semver.org](https://semver.org/)), using the format:

`[MAJOR].[MINOR].[PATCH]`
- **MAJOR** (`X.0.0`) – Incompatible API/feature changes that break backward compatibility.
- **MINOR** (`0.X.0`) – Backward-compatible new features, enhancements, or functionality changes.
- **PATCH** (`0.0.X`) – Backward-compatible bug fixes, security updates, or minor corrections.
- **Pre-release versions** – Use suffixes such as `-alpha`, `-beta`, `-rc.1` (e.g., `2.1.0-beta.1`).
- **Build metadata** – If needed, use `+build` (e.g., `2.1.0+20260314`).

---

## How to Update This Changelog

1. When making changes, update this file under the **Unreleased** section.
2. Before a new release, move changes from **Unreleased** to a new dated section with a version number.
3. Follow **Semantic Versioning** rules to categorise changes correctly.
4. If pre-release versions are used, clearly mark them as `-alpha`, `-beta`, or `-rc.X`.

---

## Release 0.10.0

- Rebased the reference implementation onto the current DPN development codebase: refreshed `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, every module, and the example `dpn_infrastructure.tfvars`.
- Enabled availability zones (`["1", "2", "3"]`) on the AKS system and workload node pools by default - UK South supports them; changing this on an existing node pool forces it to be recreated.
- Added an empty route table (UDR), associated with the `aks` subnet, so a firewall/NVA can be wired in as the default route later without any AKS module change. `outbound_type` stays on the Standard Load Balancer until you do that.
- Made the Bastion admin-access path optional via a new `bastion_enabled` variable (default `true`). The alternative - an existing AVD (Azure Virtual Desktop) desktop with private network line of sight into the VNet - needs neither the `bastion` nor an extra module; which one to use is a per-customer decision.
- Removed the `ampls` module from this build - it isn't present in the source codebase this release was rebased from.
- Renamed `aks_vault_workload_identity_enabled` to `workload_identity_key_vault_access_enabled`, and removed the disabled `aks_vault` cluster and `application_gateway` module/variables entirely, along with their now-unused variables.
- Confirmed the developer storage account's Azure Files share stays removed (see Release 0.9.1) in the rebased configuration.

---

## Release 0.9.1

- Removed the developer storage account's optional Azure Files share and its private endpoint (`dev_storage_create_file_share`, `dev_storage_file_share_name`, `dev_storage_file_share_quota_gb`, `dev_storage_create_file_endpoint`) from the example environment, root variables, and `dev_storage` module wiring.

---

## Release 0.9.0

- Established initial project implementation, repository baseline, and README documentation.
- Added Bicep bootstrap stack for OpenTofu remote state management, including the Azure Storage Account backend and its private endpoint.
- Added Bicep permissions template to provision the CI/CD deploy identity used by the pipelines.
- Implemented core networking module covering subnet and NSG creation within an existing, customer-owned VNet.
- Added AKS module for private cluster provisioning, including system/workload node pools, Key Vault CSI driver, and OIDC workload identity federation.
- Implemented Key Vault module for customer-managed key (CMK) encryption and centralized secrets/keys management.
- Added workload identity module for Microsoft Entra Workload ID federation between AKS ServiceAccounts and Key Vault.
- Added container registry module (Azure Container Registry) with automatic pull access granted to AKS.
- Added Log Analytics and AMPLS modules for centralized observability and optional private-endpoint ingestion.
- Added bastion and VM modules for private, Bastion-brokered administrative access to the cluster.
- Implemented storage, Event Grid, and Service Bus modules to support the file-scanning application pattern.
- Added GitHub Actions and Azure DevOps pipelines for bootstrap, deploy, destroy, and (Azure DevOps) compliance scanning.
- Reduced configuration to a single `dpn_infrastructure` example environment with synthetic documentation values for public reference use.
- Added prerequisites, deployment, testing/validation, and security/compliance documentation.
 
---

## Maintained by the National Energy System Operator (NESO)

Copyright 2026 NESO and the Crown.  This work is licensed under the Open Government Licence 3.0 (OGL). This work has been developed by NESO using content licensed by the Department for Business and Trade (UK) under the OGL.   
 
Licensed under the Open Government Licence v3.0.

For full licensing terms, [OGL_LICENSE.md](./OGL_LICENSE.md)
