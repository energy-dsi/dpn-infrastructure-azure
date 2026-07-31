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
