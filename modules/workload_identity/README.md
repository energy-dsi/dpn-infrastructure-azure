# Workload Identity Module

## Purpose in this architecture

This is how a specific application running as a pod on `modules/aks` reaches `modules/keyvault` for secrets, without a connection string or client secret stored anywhere in your container image or Kubernetes manifests. For example, if you build the file-scanning consumer described in the root `README.md` as a container running in AKS (rather than an Azure Function), this is the module that lets that pod read whatever secret it needs directly from Key Vault.

This module creates an Azure AD Workload Identity for AKS, enabling Kubernetes pods to authenticate to Azure services (like Key Vault) without storing credentials.

## Features

- **User-Assigned Managed Identity**: Creates Azure AD identity for workload
- **Federated Identity Credential**: Links Kubernetes Service Account to Azure AD
- **Key Vault RBAC**: Automatically grants Key Vault Secrets User role
- **OIDC Integration**: Uses AKS OIDC issuer for token exchange

## Prerequisites

AKS cluster must have:
- `oidc_issuer_enabled = true`
- `workload_identity_enabled = true`

## Usage

```terraform
module "workload_identity" {
  source = "./modules/workload_identity"
  
  identity_name        = "id-aks-workload-dev-uks-01"
  resource_group_name  = "rg-aks-dev-uks-01"
  location             = "uksouth"
  oidc_issuer_url      = module.aks.oidc_issuer_url
  namespace            = "default"
  service_account_name = "app-service-account"
  key_vault_id         = module.keyvault.key_vault_id
  tags                 = var.tags
}
```

## Kubernetes Configuration

### 1. Create Service Account

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: default
  annotations:
    azure.workload.identity/client-id: "<workload_identity.client_id>"
```

### 2. Deploy Pod with Workload Identity

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  namespace: default
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: app-service-account
  containers:
  - name: app
    image: myapp:latest
    env:
    - name: AZURE_CLIENT_ID
      value: "<workload_identity.client_id>"
    - name: KEY_VAULT_URL
      value: "https://vault-dpn-dev-uks-08.vault.azure.net/"
```

### 3. Access Key Vault from Application

#### Python Example

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()
vault_url = os.environ["KEY_VAULT_URL"]
client = SecretClient(vault_url=vault_url, credential=credential)

secret = client.get_secret("my-secret")
print(f"Secret value: {secret.value}")
```

#### .NET Example

```csharp
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var credential = new DefaultAzureCredential();
var vaultUrl = Environment.GetEnvironmentVariable("KEY_VAULT_URL");
var client = new SecretClient(new Uri(vaultUrl), credential);

KeyVaultSecret secret = await client.GetSecretAsync("my-secret");
Console.WriteLine($"Secret value: {secret.Value}");
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| identity_name | Name of the managed identity | string | - | yes |
| resource_group_name | Resource group name | string | - | yes |
| location | Azure region | string | - | yes |
| oidc_issuer_url | AKS OIDC issuer URL | string | - | yes |
| namespace | Kubernetes namespace | string | "default" | no |
| service_account_name | Kubernetes ServiceAccount name | string | - | yes |
| key_vault_id | Key Vault resource ID | string | "" | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| client_id | Client ID for K8s ServiceAccount annotation |
| principal_id | Principal ID (Object ID) of the identity |
| identity_id | Resource ID of the managed identity |
| identity_name | Name of the managed identity |
| federated_credential_id | Resource ID of the federated credential |

## How It Works

1. **Identity Creation**: User-assigned managed identity created in Azure AD
2. **Federation**: Federated credential links K8s ServiceAccount to Azure AD identity
3. **Token Exchange**: AKS OIDC provider issues tokens, Azure AD validates and exchanges
4. **Authorization**: Managed identity has Key Vault Secrets User role
5. **Application Access**: Pods use DefaultAzureCredential to access Key Vault

## Troubleshooting

### Error: "federated client is not present"
- Ensure `azurerm_federated_identity_credential` is created
- Verify OIDC issuer URL is correct
- Check ServiceAccount namespace and name match exactly

### Error: "Authorization failed"
- Verify Key Vault RBAC role assignment exists
- Check managed identity has proper permissions
- Ensure Key Vault uses Azure RBAC (not access policies)

### Pod can't get token
- Verify pod has label `azure.workload.identity/use: "true"`
- Check ServiceAccount has correct annotation
- Ensure workload identity webhook is installed in cluster
