targetScope = 'subscription'

@description('Environment configuration (e.g., dev, test, prod)')
param envConfig string

@description('Azure region for resources')
param region string

@description('Bootstrap resource group name')
param bootstrapResourceGroupName string

@description('Backend storage account name')
param backendStorageAccountName string

@description('Infrastructure resource group name')
param infraResourceGroupName string

@description('Existing VNet name')
param vnetName string

@description('Existing VNet resource group name')
param vnetResourceGroupName string

@description('Tfstate subnet address prefix')
param tfstateSubnetPrefix string

@description('Name for the tfstate NSG')
param tfstateNsgName string

@description('Name for the tfstate subnet')
param tfstateSubnetName string

@description('Private DNS Zone resource ID for blob storage')
param privateDnsZoneId string

@description('Optional CIDR prefixes that require HTTPS access to tfstate private endpoint subnet.')
param tfstateAllowedSourcePrefixes array = []

@description('Enable soft delete for storage account')
param enableSoftDelete bool = true

// Create bootstrap resource group
resource bootstrapRG 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: bootstrapResourceGroupName
  location: region
  tags: {
    Environment: envConfig
    ManagedBy: 'OpenTofu'
    Purpose: 'Bootstrap'
  }
}

// Create infrastructure resource group for networking
resource infraRG 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: infraResourceGroupName
  location: region
  tags: {
    Environment: envConfig
    ManagedBy: 'OpenTofu'
    Purpose: 'Infrastructure'
  }
}

// Create tfstate NSG
module tfstateNSG 'modules/nsg.bicep' = {
  name: 'tfstate-nsg-deployment'
  scope: infraRG
  params: {
    nsgName: tfstateNsgName
    location: region
    allowedHttpsSourcePrefixes: tfstateAllowedSourcePrefixes
  }
}

// Create tfstate subnet in VNet's resource group
module tfstateSubnet 'modules/subnet.bicep' = {
  name: 'tfstate-subnet-deployment'
  scope: resourceGroup(vnetResourceGroupName)
  params: {
    vnetName: vnetName
    subnetName: tfstateSubnetName
    subnetAddressPrefix: tfstateSubnetPrefix
    nsgId: tfstateNSG.outputs.nsgId
  }
}

// Create storage account for OpenTofu state
module storageAccount 'modules/storage.bicep' = {
  name: 'storage-account-deployment'
  scope: bootstrapRG
  params: {
    storageAccountName: backendStorageAccountName
    location: region
    enableSoftDelete: enableSoftDelete
  }
}

// Create private endpoint for storage account
module privateEndpoint 'modules/privateEndpoint.bicep' = {
  name: 'private-endpoint-deployment'
  scope: bootstrapRG
  params: {
    privateEndpointName: 'pe-${backendStorageAccountName}'
    location: region
    storageAccountId: storageAccount.outputs.storageAccountId
    subnetId: tfstateSubnet.outputs.subnetId
    privateDnsZoneId: privateDnsZoneId
  }
}

output storageAccountName string = storageAccount.outputs.storageAccountName
output containerName string = storageAccount.outputs.containerName
output bootstrapResourceGroupName string = bootstrapRG.name
output infraResourceGroupName string = infraRG.name
output tfstateSubnetId string = tfstateSubnet.outputs.subnetId
output tfstateNsgId string = tfstateNSG.outputs.nsgId
output privateEndpointId string = privateEndpoint.outputs.privateEndpointId
output privateEndpointName string = privateEndpoint.outputs.privateEndpointName
