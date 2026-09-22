# DPN Infrastructure Bootstrap

This folder contains Bicep templates for bootstrapping the OpenTofu backend infrastructure for your DPN environment.

## What Gets Created

1. **Backend Resource Group** (`rg-tfstate-dpn-azure-uks-01`)
   - OpenTofu state storage account
   - Private endpoint for storage account

2. **Infrastructure Resource Group** (`rg-dpn-azure-uks-01`) *(already exists)*
   - NSG for the tfstate subnet
   - VNet subnets (managed by OpenTofu)

3. **Tfstate Subnet**
   - Created in existing VNet (`vnet-dpn-azure-uks-01`)
   - Address prefix: `10.0.1.144/28`
   - Attached NSG: `nsg-dpn-azure-uks-tfstate-01`

4. **Storage Account** (`sttfdpnazureuks01`)
   - SKU: Standard_RAGRS
   - Public access: Disabled
   - Minimum TLS: 1.2
   - Container: `tfstate`

5. **Private Endpoint** (`pe-sttfdpnazureuks01`)
   - Links storage to tfstate subnet
   - DNS zone: `privatelink.blob.core.windows.net`

## Prerequisites

- Azure CLI installed and logged in
- Set subscription: `az account set --subscription "<your-subscription-id>"`
- Existing VNet (`vnet-dpn-azure-uks-01`) in resource group (`rg-dpn-azure-uks-01`)
- Access to the private DNS zone in the subscription hosting it (`<your-private-dns-zone-subscription-id>` - same as your subscription ID above if you don't use a separate one) - see `permissions/README.md` for the roles required

## Deploying via CI/CD

Most customers will run this via the "DPN - Bootstrap Infrastructure" pipeline
rather than the manual CLI steps below:

- GitHub Actions: `.github/workflows/bootstrap-dpn.yml` - non-secret naming/
  region values come from repository variables (Settings -> Secrets and
  variables -> Actions -> Variables tab); see the workflow header comment for
  the full list.
- Azure DevOps: `azure-pipelines/bootstrap-dpn.yml` - the same values come
  from the `dpn-config` variable group (Pipelines -> Library).

## Deploy Bootstrap

```powershell
az account set --subscription "<your-subscription-id>"

az deployment sub create `
  --location "UK South" `
  --template-file main.bicep `
  --parameters `
   envConfig="dev" `
    region="UK South" `
   bootstrapResourceGroupName="rg-tfstate-dpn-azure-uks-01" `
   backendStorageAccountName="sttfdpnazureuks01" `
   infraResourceGroupName="rg-dpn-azure-uks-01" `
   vnetName="vnet-dpn-azure-uks-01" `
   vnetResourceGroupName="rg-dpn-azure-uks-01" `
   tfstateSubnetPrefix="10.0.1.144/28" `
   tfstateNsgName="nsg-dpn-azure-uks-tfstate-01" `
   tfstateSubnetName="snet-dpn-azure-uks-tfstate" `
    privateDnsZoneId="/subscriptions/<your-private-dns-zone-subscription-id>/resourceGroups/rg-pdns-prd-uks-01/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
```

All names above (resource groups, storage account, subnet/NSG names) are examples - substitute your own; only their *shape* (e.g. globally-unique storage account name, resource group naming convention) matters.

## After Bootstrap — OpenTofu Init & Deploy

```powershell
cd ../  # dpn-azure-infrastructure/

# Initialize with remote backend
tofu init -reconfigure `
   -backend-config="resource_group_name=rg-tfstate-dpn-azure-uks-01" `
   -backend-config="storage_account_name=sttfdpnazureuks01" `
  -backend-config="container_name=tfstate" `
   -backend-config="key=dpn.tfstate"

# Plan
tofu plan -var-file=environments/dpn_infrastructure.tfvars -out=dpn.tfplan

# Apply
tofu apply dpn.tfplan
```

## Environment Details

| Property                | Value                                      |
|-------------------------|---------------------------------------------|
| Subscription            | `<your-subscription-name>`                 |
| Subscription ID         | `<your-subscription-id>`                   |
| Location                | UK South                                   |
| VNet CIDR               | `10.0.1.0/24`                              |
| VNet Name               | `vnet-dpn-azure-uks-01`                    |
| VNet Resource Group     | `rg-dpn-azure-uks-01`                      |
| Environment             | dev                                        |
| Naming Convention       | `<type>-dpn-azure-uks-<##>`                |
| Private DNS Zone Sub ID | `<your-private-dns-zone-subscription-id>`  |
| Private DNS Zone RG     | `rg-pdns-prd-uks-01`                       |

## Cleanup

```powershell
# Delete backend resource group
az group delete --name rg-tfstate-dpn-azure-uks-01 --yes

# Delete tfstate subnet and NSG
az network vnet subnet delete --resource-group rg-dpn-azure-uks-01 --vnet-name vnet-dpn-azure-uks-01 --name tfstate
az network nsg delete --resource-group rg-dpn-azure-uks-01 --name nsg-dpn-azure-uks-tfstate-01
```
