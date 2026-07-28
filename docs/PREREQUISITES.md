# Prerequisites

Everything on this page must be true **before** you run the bootstrap pipeline. Nothing here is created by this codebase - it's what your tenant/platform team needs to have ready first.

## 1. Azure prerequisites

| Requirement | Notes |
|---|---|
| An Azure subscription | This is "your DPN subscription" throughout the rest of the docs - the one this codebase deploys into. |
| An existing Virtual Network, with free address space | This codebase creates subnets inside it; it does not create the VNet itself. Plan address space for: AKS, Key Vault, ACR, Log Analytics, storage, VM, and (if used) Event Grid/Service Bus - see `dpn-azure-infrastructure/environments/dpn_infrastructure.tfvars`'s `subnets` map for the full example layout and sizing. |
| A subscription (or resource group) hosting shared private DNS zones | Every private endpoint this codebase creates registers into a private DNS zone - `privatelink.vaultcore.azure.net`, `privatelink.blob.core.windows.net`, `privatelink.azurecr.io`, `privatelink.<region>.azmk8s.io`, etc. This can be the same subscription as your DPN subscription, or a separate centrally-managed one - see `permissions/README.md` step 2. |
| A self-hosted CI/CD runner/agent with network line-of-sight to your VNet | GitHub-hosted or Microsoft-hosted Azure DevOps agents cannot reach private endpoints. You need your own runner/agent (any VM or container with network access to the VNet above) registered to your GitHub organization or Azure DevOps project. Labeled `self-hosted` for GitHub Actions; any agent pool name for Azure DevOps. |
| The `EncryptionAtHost` feature registered on your subscription | Required for AKS node disk host encryption. The deploy pipeline registers this automatically on first run if missing (takes a few minutes) - no action needed up front, just be aware the first deploy may pause here. |

## 2. Identity prerequisites

Run through `permissions/README.md` in full before continuing. In short, you need:

1. A deploy identity created in your DPN subscription (`permissions/dpn-cicd-identity.bicep`) - this is what your CI/CD pipelines authenticate as.
2. A federated identity credential configured on that identity for your CI/CD platform's OIDC issuer, so it can authenticate without a stored client secret.
3. If your private DNS zones live in a different subscription than your DPN subscription: the roles listed in `permissions/README.md` step 2, granted by whoever administers that subscription.

You will need the deploy identity's **`clientId`** and **`principalId`** outputs for the next section.

## 3. CI/CD platform prerequisites

Pick the section for whichever platform you're using. **Every value below is something you configure once, before the first pipeline run** - the pipelines will fail fast with a clear error if any of it is missing.

### GitHub Actions

Go to your repository's **Settings → Secrets and variables → Actions**.

**Secrets tab** - add these:

| Secret | Value |
|---|---|
| `AZURE_CLIENT_ID` | `clientId` output from `permissions/dpn-cicd-identity.bicep` |
| `AZURE_TENANT_ID` | Your Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Your DPN subscription ID |
| `PRIVATE_DNS_ZONE_SUBSCRIPTION_ID` | Subscription hosting your private DNS zones (same value as `AZURE_SUBSCRIPTION_ID` if you don't use a separate one) |
| `VM_ADMIN_PASSWORD` | Admin password for the jump host VM - generate a strong one and store it nowhere else |

**Variables tab** - add these (non-secret, but still needed for the pipelines to know what to name/configure):

| Variable | Example value | Used by |
|---|---|---|
| `AZURE_LOCATION` | `uksouth` | bootstrap, deploy |
| `ENVIRONMENT_NAME` | `dev` | bootstrap |
| `BACKEND_RESOURCE_GROUP` | `rg-tfstate-dpn-uks-01` | bootstrap, deploy, destroy |
| `BACKEND_STORAGE_ACCOUNT` | `sttfdpnuks01` (must be globally unique) | bootstrap, deploy, destroy |
| `VNET_RESOURCE_GROUP` | `rg-dpn-uks-01` | bootstrap, deploy |
| `VNET_NAME` | `vnet-dpn-uks-01` | bootstrap, deploy |
| `TFSTATE_SUBNET_PREFIX` | `10.0.1.144/28` | bootstrap |
| `TFSTATE_NSG_NAME` | `nsg-dpn-uks-tfstate` | bootstrap |
| `TFSTATE_SUBNET_NAME` | `snet-dpn-uks-tfstate` | bootstrap |
| `PRIVATE_DNS_ZONE_RESOURCE_GROUP` | `rg-pdns-uks-01` | bootstrap |
| `TF_STATE_RG` | same as `BACKEND_RESOURCE_GROUP` | deploy, destroy |
| `TF_STATE_STORAGE` | same as `BACKEND_STORAGE_ACCOUNT` | deploy, destroy |

Then configure the manual-approval environment: **Settings → Environments → New environment**, name it `dpn-approval`, and add required reviewers under "Deployment protection rules".

### Azure DevOps

Go to **Pipelines → Library** in your project.

Create a variable group named **`dpn-secrets`** and mark every value in it as secret (the lock icon):

| Variable | Value |
|---|---|
| `ARM_SUBSCRIPTION_ID` | Your DPN subscription ID |
| `PRIVATE_DNS_ZONE_SUBSCRIPTION_ID` | Subscription hosting your private DNS zones (same value as `ARM_SUBSCRIPTION_ID` if you don't use a separate one) |
| `VM_ADMIN_PASSWORD` | Admin password for the jump host VM |

Create a second variable group named **`dpn-config`** (non-secret):

| Variable | Example value |
|---|---|
| `AZURE_LOCATION` | `uksouth` |
| `ENVIRONMENT_NAME` | `dev` |
| `BACKEND_RESOURCE_GROUP` | `rg-tfstate-dpn-uks-01` |
| `BACKEND_STORAGE_ACCOUNT` | `sttfdpnuks01` (must be globally unique) |
| `VNET_RESOURCE_GROUP` | `rg-dpn-uks-01` |
| `VNET_NAME` | `vnet-dpn-uks-01` |
| `TFSTATE_SUBNET_PREFIX` | `10.0.1.144/28` |
| `TFSTATE_NSG_NAME` | `nsg-dpn-uks-tfstate` |
| `TFSTATE_SUBNET_NAME` | `snet-dpn-uks-tfstate` |
| `PRIVATE_DNS_ZONE_RESOURCE_GROUP` | `rg-pdns-uks-01` |
| `TF_STATE_RG` | same as `BACKEND_RESOURCE_GROUP` |
| `TF_STATE_STORAGE` | same as `BACKEND_STORAGE_ACCOUNT` |

Unlike GitHub Actions, Azure DevOps doesn't need `AZURE_CLIENT_ID`/`AZURE_TENANT_ID` as pipeline variables - those live inside the **service connection** instead (next step).

Create the service connection: **Project settings → Service connections → New service connection → Azure Resource Manager → Workload Identity Federation**. Point it at your DPN subscription and your deploy identity from `permissions/dpn-cicd-identity.bicep`. Note the service connection's name - every pipeline in `azure-pipelines/` takes it as a `serviceConnection` parameter (default value `sc-dpn-azure` - override it at run time if you named yours differently).

Create the approval environment: **Pipelines → Environments → New environment**, name it `dpn-approval`, then add an **Approvals** check under "Approvals and checks".

## 4. What happens if something is missing

Every pipeline validates its own prerequisites early and fails with a specific error rather than a confusing downstream failure - e.g. "OpenTofu state storage not found - run the bootstrap pipeline first", or a missing-secret error naming the exact secret. If a pipeline run fails, read the first error in the log, not the last one.

## Next step

Once everything above is in place, continue to [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).
