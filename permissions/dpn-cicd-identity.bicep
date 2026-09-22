// =============================================================================
// DPN CI/CD Deployment Identity
// =============================================================================
// Creates a dedicated user-assigned managed identity for your DPN environment
// and grants it Owner on that subscription only.
//
// Run ONCE from a privileged pipeline (Owner on your DPN subscription):
//
//   az account set --subscription <your-subscription-id>
//   az deployment sub create \
//     --location uksouth \
//     --template-file permissions/dpn-cicd-identity.bicep \
//     --parameters environmentName=dev
//
// After deployment, note the 'clientId' and 'principalId' outputs:
//   - clientId becomes the AZURE_CLIENT_ID secret (GitHub Actions) / the
//     identity behind your service connection (Azure DevOps) that the
//     deployment pipelines authenticate as.
//   - Configure a federated identity credential on this identity for your
//     CI/CD platform's OIDC issuer (GitHub Actions or Azure DevOps Workload
//     Identity Federation) so it can authenticate without a client secret:
//
//   az identity federated-credential create \
//     --name "github-actions-dpn" \
//     --identity-name "id-dpn-<environmentName>-deploy" \
//     --resource-group "rg-dpn-<environmentName>-cicd-uks-01" \
//     --issuer "https://token.actions.githubusercontent.com" \
//     --subject "repo:<your-org>/<your-repo>:ref:refs/heads/<your-branch>" \
//     --audiences "api://AzureADTokenExchange"
//
// See permissions/README.md for the full walkthrough.
// =============================================================================

targetScope = 'subscription'

@description('Environment short name, e.g. dev | test | prod')
param environmentName string

@description('Azure region for resource group and identity.')
param region string = 'uksouth'

var identityName = 'id-dpn-${environmentName}-deploy'
var cicdRgName   = 'rg-dpn-${environmentName}-cicd-uks-01'

// ---------------------------------------------------------------------------
// Resource group for the CI/CD identity
// ---------------------------------------------------------------------------
resource cicdRg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name:     cicdRgName
  location: region
  tags: {
    Environment: environmentName
    ManagedBy:   'Platform'
    Purpose:     'DPN CI/CD deployment identity'
  }
}

// ---------------------------------------------------------------------------
// User-assigned managed identity — one per DPN environment
// ---------------------------------------------------------------------------
module cicdIdentity 'modules/identity.bicep' = {
  name: 'cicd-identity-deployment'
  scope: cicdRg
  params: {
    identityName:    identityName
    location:        region
    environmentName: environmentName
  }
}

// ---------------------------------------------------------------------------
// Owner on this DPN subscription only
// Gives the identity full control within the LZ boundary; it cannot affect
// other subscriptions.  Owner = Contributor + User Access Administrator,
// which is required for OpenTofu to create role assignments (AKS VNet
// contributor, kubelet AcrPull, Key Vault Secrets User, etc.) during apply.
// ---------------------------------------------------------------------------
resource ownerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  // Deterministic GUID scoped to this subscription + identity name + role.
  // Seeded from identityName (known at the start of deployment) rather than
  // the module's principalId/identityId outputs, since a resource `name`
  // must be calculable before deployment starts - module outputs aren't
  // available that early.
  name: guid(subscription().id, identityName, '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' // Owner
    )
    principalId:   cicdIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
output clientId    string = cicdIdentity.outputs.clientId
output principalId string = cicdIdentity.outputs.principalId
output identityId  string = cicdIdentity.outputs.identityId
output identityName string = identityName
