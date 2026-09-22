// =============================================================================
// User-assigned managed identity - resource-group-scoped module
// Deployed via a module (not inline) because the parent template targets
// subscription scope, and a resource can't set `scope:` to a resource group
// directly from a subscription-scoped file - only a module can.
// =============================================================================

@description('Name of the user-assigned managed identity')
param identityName string

@description('Azure region')
param location string

@description('Environment short name, e.g. dev | test | prod')
param environmentName string

resource cicdIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
  tags: {
    Environment: environmentName
    ManagedBy: 'Platform'
    Purpose: 'DPN CI/CD deployment identity'
  }
}

output clientId string = cicdIdentity.properties.clientId
output principalId string = cicdIdentity.properties.principalId
output identityId string = cicdIdentity.id
