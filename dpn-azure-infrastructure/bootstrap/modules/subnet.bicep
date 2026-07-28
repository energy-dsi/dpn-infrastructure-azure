@description('VNet name')
param vnetName string

@description('Subnet name')
param subnetName string

@description('Subnet address prefix')
param subnetAddressPrefix string

@description('NSG resource ID')
param nsgId string

// Retrieve existing VNet
resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' existing = {
  name: vnetName
}

// Create subnet with NSG
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: {
      id: nsgId
    }
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
}

output subnetId string = subnet.id
output subnetName string = subnet.name
