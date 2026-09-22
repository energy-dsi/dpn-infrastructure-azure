@description('NSG name')
param nsgName string

@description('Azure region')
param location string

@description('Optional CIDR prefixes that need HTTPS access to tfstate private endpoint subnet (e.g., GitHub runners subnet).')
param allowedHttpsSourcePrefixes array = []

var allowHttpsRules = [for (prefix, index) in allowedHttpsSourcePrefixes: {
  name: 'allow-https-to-tfstate-${index + 100}'
  properties: {
    priority: 100 + index
    access: 'Allow'
    direction: 'Inbound'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: prefix
    destinationAddressPrefix: '*'
    description: 'Allow HTTPS access to tfstate private endpoint from approved source range'
  }
}]

// Create NSG
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: allowHttpsRules
  }
  tags: {
    Purpose: 'OpenTofuStateSubnet'
  }
}

output nsgId string = nsg.id
output nsgName string = nsg.name
