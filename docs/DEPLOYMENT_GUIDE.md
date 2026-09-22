# Deployment Guide

This walks through deploying a DPN from a clean checkout of this repository. Complete [PREREQUISITES.md](PREREQUISITES.md) first - every step below assumes it's done.

## Step 1 - Create the deploy identity

Already covered in [PREREQUISITES.md](PREREQUISITES.md) §2 / `permissions/README.md`. Confirm you have:
- The deploy identity's `clientId` and `principalId`
- A federated credential configured for your CI/CD platform's OIDC issuer
- Every secret/variable from [PREREQUISITES.md](PREREQUISITES.md) §3 set in your repo/project

## Step 2 - Bootstrap the OpenTofu backend

This creates the storage account OpenTofu uses to store its state, plus the private endpoint and subnet/NSG it needs. It only needs to run once per environment, and is safe to re-run (ARM deployments are idempotent).

**GitHub Actions**: Actions tab → "DPN - Bootstrap Infrastructure" → Run workflow.

**Azure DevOps**: Pipelines → select the bootstrap pipeline → Run pipeline.

Confirm it succeeded: the run should report "private endpoint provisioned successfully". If it fails, the error will point at a specific missing prerequisite (see [PREREQUISITES.md](PREREQUISITES.md)).

## Step 3 - Fill in your configuration

Edit `dpn-azure-infrastructure/environments/dpn_infrastructure.tfvars` directly and replace every placeholder value - the deploy/destroy pipelines reference this exact file:
- Subscription IDs, tenant-specific object IDs (currently `00000000-0000-0000-0000-000000000000` placeholders)
- Resource names (the example uses a `<type>-dpn-azure-<region>-<instance>` convention - keep your own convention consistent, the exact names don't matter)
- CIDR ranges in the `subnets` map - must fit inside your existing VNet's address space and not collide with anything already using it
- `keyvault_initial_keys` / `keyvault_initial_secrets` - the example includes one CMK (`cmk-key`) used to encrypt every resource that supports customer-managed keys. Set a real `expiration_date` on every key/secret you add (see `modules/keyvault/README.md`).

If your workload doesn't need the file-scanning pattern described in the root `README.md`, remove the `event_grid`, `service_bus`, and `file_scanning_storage` module blocks from `dpn-azure-infrastructure/main.tf` and their corresponding variables from `dpn_infrastructure.tfvars` - see that README for what those modules are for before deciding.

Commit this file to your branch (it contains no secrets - the one sensitive value, `vm_admin_password`, is deliberately kept out of it and supplied by the pipeline).

## Step 4 - Plan

**GitHub Actions**: Actions tab → "DPN - Deploy Infrastructure" → Run workflow → `action: plan`.

**Azure DevOps**: Pipelines → deploy pipeline → Run pipeline → `action: plan`.

This also pushes to your trigger branch and runs `action: plan` automatically on any change under `dpn-azure-infrastructure/`. Review the plan output in the run log before proceeding - it lists every resource that will be created/changed/destroyed.

## Step 5 - Apply

Re-run the same pipeline with `action: apply`. If `require_approval` is `true` (the default), the run will pause at the approval gate - whoever you added as a required reviewer on the `dpn-approval` environment needs to approve it before `OpenTofu Apply` runs.

Expect the first apply to take a while - AKS cluster creation alone typically takes 10-15 minutes, plus RBAC propagation delays the pipeline already accounts for.

## Step 6 - Verify

The pipeline's final job checks `tofu output` for the expected resource IDs (VNet, Log Analytics, Key Vault, ACR, AKS, storage) and fails if any are missing. If it passes, your DPN is up.

To connect and look around:

```bash
# Via the jump host (see modules/bastion + modules/vm) - connect through Azure Bastion in the Portal,
# then from that VM:
az aks get-credentials --resource-group <your-aks-rg> --name <your-aks-name>
kubectl get nodes
```

## Step 7 (only if needed) - Destroy

Use the dedicated destroy pipeline, never `action: apply` with resources removed from tfvars - it has its own safeguards:

**GitHub Actions**: "DPN - DESTROY Infrastructure" → type `DESTROY-DPN` in the confirmation input → approve when prompted.

**Azure DevOps**: destroy pipeline → same confirmation parameter.

AKS has `prevent_destroy = true` by default - pass `force_destroy_aks: true` if you genuinely want to tear down the cluster too.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `tofu init` fails / times out | Your CI/CD runner/agent doesn't have network line-of-sight to the tfstate storage account's private endpoint. Re-check the self-hosted runner requirement in [PREREQUISITES.md](PREREQUISITES.md). |
| `tofu apply` fails on a role assignment with 403 | RBAC propagation delay, or the deploy identity is missing a role from `permissions/README.md`. Re-run - most of these self-heal on retry once propagation completes. |
| Event Grid stops receiving Defender for Storage events | Check `event_grid_public_network_access_enabled` is still `true` - see `modules/event_grid/README.md`. This is a real Azure platform constraint, not something to "fix" by disabling public access. |
| Plan shows unexpected changes on every run | Someone likely ran `tofu apply` locally against the same state, or two people are applying concurrently. The pipelines' `concurrency`/lock settings prevent the second case within CI, but not against local runs. |
