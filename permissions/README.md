# DPN CI/CD Identity Setup

This folder provisions the deploy identity used by the pipelines in
`.github/workflows/` and `azure-pipelines/`. It is scoped to **your own DPN
subscription only** - the subscription this codebase deploys into (the box in
the architecture diagram: networking, AKS, Key Vault, ACR, storage, Event
Grid, Service Bus, jumpbox).

## 1. Create the deploy identity (`dpn-cicd-identity.bicep`)

Creates a user-assigned managed identity in your DPN subscription and grants
it Owner scoped to that subscription only (required for OpenTofu to create
role assignments during apply - AKS kubelet AcrPull, Key Vault Secrets User,
etc.).

```bash
az account set --subscription <your-subscription-id>
az deployment sub create \
  --location uksouth \
  --template-file permissions/dpn-cicd-identity.bicep \
  --parameters environmentName=dev
```

Note the `clientId` and `principalId` outputs - `clientId` becomes the
`AZURE_CLIENT_ID` secret (GitHub) / service connection identity (Azure
DevOps) the pipelines authenticate as. Configure a federated identity
credential on this identity for your CI/CD platform's OIDC issuer (GitHub
Actions or Azure DevOps Workload Identity Federation) so it can authenticate
without a client secret.

## 2. Private DNS zone access (platform/tenant team prerequisite)

This architecture registers private endpoints (Key Vault, ACR, storage, Event
Grid, Service Bus, AKS) into private DNS zones. Those zones are typically
centrally managed shared infrastructure that lives outside the DPN
subscription this codebase deploys - so granting access to them is **not**
something this repo provisions for you. Ask whoever administers that
subscription to run the following against the deploy identity's
`principalId` from step 1:

```bash
# Run by an Owner/administrator of the subscription hosting your shared
# private DNS zones - substitute your own subscription/resource group/zone names.
az account set --subscription <your-private-dns-zone-subscription-id>

# Lets the deploy identity register A records in each zone it needs
# (privatelink.vaultcore.azure.net, privatelink.azurecr.io,
# privatelink.blob.core.windows.net, privatelink.<region>.azmk8s.io, etc.)
az role assignment create \
  --assignee-object-id <deploy-identity-principalId> \
  --assignee-principal-type ServicePrincipal \
  --role "Private DNS Zone Contributor" \
  --scope "/subscriptions/<your-private-dns-zone-subscription-id>/resourceGroups/<your-private-dns-zone-resource-group>"

# Lets OpenTofu grant the AKS cluster's own managed identity
# "Private DNS Zone Contributor" on the AKS zone during apply
# (azurerm_role_assignment.aks_dns_contributor) - without this, apply fails
# with 403 Forbidden at that resource.
az role assignment create \
  --assignee-object-id <deploy-identity-principalId> \
  --assignee-principal-type ServicePrincipal \
  --role "Role Based Access Control Administrator" \
  --scope "/subscriptions/<your-private-dns-zone-subscription-id>/resourceGroups/<your-private-dns-zone-resource-group>/providers/Microsoft.Network/privateDnsZones/privatelink.<region>.azmk8s.io"
```

If your private DNS zones live in the *same* subscription you're deploying
into, run these against that subscription instead - the deploy identity
already has Owner there from step 1, so this step becomes a formality (Owner
already includes both roles above).
