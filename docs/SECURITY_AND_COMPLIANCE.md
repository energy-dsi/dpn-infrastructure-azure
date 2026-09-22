# Security and Compliance Posture

This page explains what security controls this codebase implements, how they relate to common frameworks like the CIS Azure Foundations Benchmark and NIST 800-53, and - just as importantly - what it does *not* claim.

See the root `README.md`'s ["Scope, support, and things to know before you rely on this"](../README.md#scope-support-and-things-to-know-before-you-rely-on-this) section for the equivalent disclaimer on non-compliance topics (warranty/support, disaster recovery, cost, and landing-zone assumptions).

## What this is not

**This codebase is not, and cannot be, "CIS/NIST compliant" on its own.** Compliance frameworks are assessed against a *deployed, operated* environment - they include administrative and procedural controls (access reviews, incident response, vulnerability management cadence, personnel training, monitoring SLAs) that live entirely outside Terraform. Deploying this codebase gives you a head start on the technical controls; it does not constitute an audit, and nobody should represent it as one.

## Controls implemented by default

| Area | What's implemented | Relates to |
|---|---|---|
| Network isolation | Every data-plane resource (Key Vault, ACR, storage, AKS API server, Service Bus, VM) is reachable only via private endpoint - no public network access by default | CIS Azure Foundations 6-7 (Networking), NIST 800-53 SC-7 (Boundary Protection) |
| Encryption at rest | Customer-managed key (CMK) support across storage, ACR, AKS node disks/etcd, Service Bus, and VM OS disks - see each module's "Customer-Managed Key" section | CIS Azure Foundations 8 (Other Security Considerations), NIST 800-53 SC-28 (Protection of Information at Rest) |
| Encryption in transit | TLS 1.2 minimum enforced on storage and Service Bus; AKS API server and all private endpoints use TLS | CIS Azure Foundations 7 (Networking), NIST 800-53 SC-8 |
| Identity and access | RBAC-only authorization on Key Vault (no access policies); Azure AD-only on AKS (local accounts disabled); workload identity federation for pod-to-Azure auth instead of stored credentials; storage accounts default to Azure AD/RBAC access instead of account keys | CIS Azure Foundations 1 (Identity), 4 (Key Vault), NIST 800-53 AC-3, IA-2 |
| Audit logging | Every module's diagnostic settings feed a central Log Analytics workspace by default | CIS Azure Foundations 5 (Logging and Monitoring), NIST 800-53 AU-2, AU-12 |
| Secrets management | Centralized in Key Vault; `expiration_date` supported (and should always be set) on every secret/key | CIS Azure Foundations 4 (Key Vault), NIST 800-53 SC-12 |
| Least privilege | Per-principal role assignments (Data Reader/Sender/Contributor/Owner patterns) instead of broad built-in roles, throughout | NIST 800-53 AC-6 |

## Known gaps in the default configuration, and why

The default configuration in `dpn-azure-infrastructure/environments/dpn_infrastructure.tfvars` targets a dev/test tier - clarity and cost over maximum hardening. Every gap is tracked with its rationale in **`.checkov.yaml`** (soft-fail exceptions) rather than silently accepted, so you can see exactly what to revisit before a production deployment. As of this writing, that list includes things like:

- Microsoft Defender for Containers/Cloud not enabled (subscription-level, billable, and often managed centrally by a tenant's security team rather than per-workload)
- Key Vault not using HSM-backed keys (requires Premium SKU - a real cost tradeoff)
- Key Vault public network access and firewall rules not fully locked down
- ACR geo-replication not configured (requires choosing a target region - a real architecture decision, not a default we can make for you)

One item is **not** a gap to fix: Event Grid's public network access is intentionally left enabled when the topic receives Microsoft Defender for Storage events, because Defender for Storage cannot deliver those events to a private-endpoint-only topic. See `modules/event_grid/README.md`.

Before promoting any environment beyond dev/test, review `.checkov.yaml` in full and decide, deliberately, which exceptions still apply to you.

## Running your own compliance scan

This repository ships (but does not automatically run) config for three open-source scanners - install them yourself and point them at these configs:

Run these from the repository root - `--var-file`/`--tf-vars` resolve relative to your current directory, not to the scanned directory, so dropping the `dpn-azure-infrastructure/` prefix silently loads the wrong (or no) tfvars file:

```bash
# Compliance-mapped security scan
checkov -d dpn-azure-infrastructure --framework terraform --config-file .checkov.yaml --var-file dpn-azure-infrastructure/environments/dpn_infrastructure.tfvars --compact

# Infrastructure misconfiguration scan
trivy fs dpn-azure-infrastructure --scanners misconfig --tf-vars dpn-azure-infrastructure/environments/dpn_infrastructure.tfvars --ignorefile .trivyignore

# Terraform-specific static analysis
tflint --config .tflint.hcl --recursive --chdir dpn-azure-infrastructure
```

See `docs/TESTING_AND_VALIDATION.md` for what these already report against the default configuration.

## If you need an actual attestation

Compliance certification requires a real audit - internal or third-party - of your deployed, operated environment against the specific framework and scope you need (CIS Benchmark level 1/2, NIST 800-53 baseline, a customer contractual requirement, etc.). Use the tables above as a starting point for that conversation with your compliance team, not as a substitute for it.
