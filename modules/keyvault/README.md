# Azure Key Vault Module

## Purpose in this architecture

Central secrets/keys store for the deployment. Holds application secrets (`keyvault_initial_secrets`), rotation-policy-managed keys (`keyvault_initial_keys`), and a self-signed Notation signing certificate (`keyvault_initial_certificates`) used for AKS image-signature verification via Ratify. Of the modules in this build, only `container_registry` currently consumes a key from here for its own customer-managed-key encryption - `aks`, `storage`, `vm`, and `service_bus` don't reference a Key Vault key for encryption at rest.

This module deploys an enterprise-grade Azure Key Vault with private endpoint connectivity, RBAC authorization, network security, and automated key rotation policies.

## Features

### Security & Access Control
- **RBAC Authorization** - Azure AD role-based access (no access policies)
- **Private Endpoint** - Secure access via VNet, no public exposure
- **Network ACLs** - IP filtering and subnet restrictions
- **Purge Protection** - Prevents accidental permanent deletion
- **Soft Delete** - 90-day retention for deleted items
- **Audit Logging** - All operations logged to Log Analytics

### Integration Features
- **Disk Encryption** - Enabled for Azure Disk Encryption
- **VM Deployment** - VMs can retrieve certificates
- **ARM Templates** - Resource Manager can retrieve secrets
- **AKS Integration** - Ready for Key Vault CSI driver

### High Availability
- **Zone Redundancy** - Built-in with Azure Key Vault
- **Geo-Replication** - Automatic with Premium SKU
- **99.9% SLA** - Standard availability guarantee

### Key Management
- **Automated Rotation** - Configurable rotation policies for keys
- **HSM Support** - Premium SKU for hardware security modules
- **Key Types** - RSA, EC, and oct keys supported
- **Secret Management** - Secure storage for passwords, connection strings

### Networking
- **Private DNS Zone** - `privatelink.vaultcore.azure.net` with VNet linking
- **Dedicated Subnet** - `keyvault` subnet (10.0.5.0/24)
- **Private Endpoint** - Single subresource: `vault`

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  VNet: vnet-dpn-azure-uks-01 (10.0.0.0/16)           │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ keyvault subnet (10.0.5.0/24)                │  │
│  │   └─ Key Vault Private Endpoint              │  │
│  │      - privatelink.vaultcore.azure.net       │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ aks subnet (10.0.2.0/24)                    │  │
│  │   └─ AKS Cluster                             │  │
│  │      - Key Vault CSI Driver                  │  │
│  │      - Access secrets via managed identity   │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘

Key Vault (RBAC-enabled)
├─ Private Endpoint (VNet Only)
├─ Network ACLs (Default Deny)
├─ Soft Delete (90 days)
├─ Purge Protection (Enabled)
└─ Role Assignments
   ├─ Key Vault Administrator
   ├─ Key Vault Secrets Officer
   └─ Key Vault Secrets User
```

## Usage

### Minimum Configuration

```hcl
module "keyvault" {
  source = "./keyvault"

  keyvault_name                         = "kv-dpn-azure-uks-01"
  location                              = "UK South"
  resource_group_name                   = "rg-kv-dpn-azure-uks-01"
  
  # SKU
  keyvault_sku_name                     = "standard"  # or "premium" for HSM
  
  # Security settings
  purge_protection_enabled              = true
  soft_delete_retention_days            = 90
  public_network_access_enabled         = false
  
  # Existing VNet
  vnet_name                             = "vnet-dpn-azure-uks-01"
  vnet_resource_group_name              = "rg-dpn-azure-uks-01"
  
  # RBAC assignments
  key_vault_admin_object_ids            = ["xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]
  
  # Log Analytics
  log_analytics_workspace_name          = "law-dpn-azure-uks-01"
  log_analytics_resource_group_name     = "rg-law-dpn-azure-uks-01"
  
  tags = {
    Environment = "Development"
    Project     = "DPN"
    ManagedBy   = "OpenTofu"
  }
}
```

### Full Configuration with Secrets and Keys

```hcl
module "keyvault" {
  source = "./keyvault"

  keyvault_name                         = "kv-dpn-azure-uks-01"
  location                              = "UK South"
  resource_group_name                   = "rg-kv-dpn-azure-uks-01"
  
  # SKU - use premium for HSM-backed keys
  keyvault_sku_name                     = "premium"
  
  # Security settings
  purge_protection_enabled              = true
  soft_delete_retention_days            = 90
  public_network_access_enabled         = false
  enabled_for_disk_encryption           = true
  enabled_for_deployment                = true
  enabled_for_template_deployment       = true
  
  # Network security
  network_acls_enabled                  = true
  network_acls_default_action           = "Deny"
  network_acls_bypass                   = "AzureServices"
  allowed_ip_ranges                     = []  # No public IPs allowed
  allowed_subnet_ids                    = []  # Add subnet IDs if needed
  
  # RBAC assignments
  key_vault_admin_object_ids = [
    "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Admin users/groups
  ]
  
  key_vault_secrets_officer_object_ids = [
    "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"  # CI/CD service principals
  ]
  
  key_vault_secrets_user_object_ids = [
    "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"  # AKS managed identity
  ]
  
  # Initial secrets
  initial_secrets = {
    "database-password"     = "P@ssw0rd123!"
    "api-key"               = "sk-1234567890abcdef"
    "storage-connection"    = "DefaultEndpointsProtocol=https;..."
  }
  
  # Initial keys with rotation
  initial_keys = {
    "encryption-key" = {
      key_type                      = "RSA"
      key_size                      = 2048
      key_opts                      = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
      enable_rotation               = true
      rotation_time_before_expiry   = "P30D"   # Rotate 30 days before expiry
      rotation_expire_after         = "P90D"   # Expire after 90 days
      rotation_notify_before_expiry = "P29D"   # Notify 29 days before expiry
    }
    "signing-key" = {
      key_type        = "RSA"
      key_size        = 4096
      key_opts        = ["sign", "verify"]
      enable_rotation = false
    }
  }
  
  # Existing VNet
  vnet_name                             = "vnet-dpn-azure-uks-01"
  vnet_resource_group_name              = "rg-dpn-azure-uks-01"
  
  # Log Analytics
  log_analytics_workspace_name          = "law-dpn-azure-uks-01"
  log_analytics_resource_group_name     = "rg-law-dpn-azure-uks-01"
  
  tags = {
    Environment = "Development"
    Project     = "DPN"
    ManagedBy   = "OpenTofu"
    Compliance  = "PCI-DSS"
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `keyvault_name` | Key Vault name (3-24 chars) | string | - | yes |
| `location` | Azure region | string | `UK South` | no |
| `resource_group_name` | Resource group name | string | - | yes |
| `keyvault_sku_name` | SKU (standard/premium) | string | `standard` | no |
| `soft_delete_retention_days` | Soft delete retention (7-90) | number | `90` | no |
| `purge_protection_enabled` | Enable purge protection | bool | `true` | no |
| `enabled_for_disk_encryption` | Enable for disk encryption | bool | `true` | no |
| `enabled_for_deployment` | Enable for VM deployment | bool | `true` | no |
| `enabled_for_template_deployment` | Enable for ARM templates | bool | `true` | no |
| `public_network_access_enabled` | Allow public access | bool | `false` | no |
| `vnet_name` | Existing VNet name | string | `vnet-dpn-azure-uks-01` | no |
| `vnet_resource_group_name` | VNet resource group | string | `rg-dpn-azure-uks-01` | no |
| `network_acls_enabled` | Enable network ACLs | bool | `true` | no |
| `network_acls_bypass` | ACL bypass (AzureServices/None) | string | `AzureServices` | no |
| `network_acls_default_action` | Default action (Allow/Deny) | string | `Deny` | no |
| `allowed_ip_ranges` | Allowed IP ranges | list(string) | `[]` | no |
| `allowed_subnet_ids` | Allowed subnet IDs | list(string) | `[]` | no |
| `key_vault_admin_object_ids` | Admin role object IDs | list(string) | `[]` | no |
| `key_vault_secrets_officer_object_ids` | Secrets Officer role object IDs | list(string) | `[]` | no |
| `key_vault_secrets_user_object_ids` | Secrets User role object IDs | list(string) | `[]` | no |
| `initial_secrets` | Initial secrets map | map(string) | `{}` | no |
| `initial_keys` | Initial keys map | map(object) | `{}` | no |
| `log_analytics_workspace_name` | Log Analytics workspace | string | - | yes |
| `log_analytics_resource_group_name` | Log Analytics RG | string | - | yes |
| `tags` | Resource tags | map(string) | - | yes |

## Outputs

- `keyvault_id` - Key Vault resource ID
- `keyvault_name` - Key Vault name
- `keyvault_uri` - Key Vault URI (e.g., `https://kv-dpn-azure-uks-01.vault.azure.net/`)
- `keyvault_tenant_id` - Tenant ID
- `private_endpoint_id` - Private endpoint ID
- `private_endpoint_ip_address` - Private IP address
- `keyvault_subnet_id` - Key Vault subnet ID
- `private_dns_zone_id` - Private DNS zone ID
- `secret_ids` - Map of secret names to IDs
- `key_ids` - Map of key names to IDs

## RBAC Roles

### Key Vault Administrator
Full access to all Key Vault operations. Assign to:
- DevOps administrators
- Security teams
- Break-glass accounts

### Key Vault Secrets Officer
Create, read, update, and delete secrets. Assign to:
- CI/CD pipelines
- Application deployment identities
- Secret rotation services

### Key Vault Secrets User
Read-only access to secrets. Assign to:
- AKS managed identities
- Application managed identities
- Read-only monitoring services

## Using with AKS (CSI Driver)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: secrets-store
      mountPath: "/mnt/secrets-store"
      readOnly: true
  volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: "azure-kvs"
---
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kvs
spec:
  provider: azure
  parameters:
    keyvaultName: "kv-dpn-azure-uks-01"
    tenantId: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    objects: |
      array:
        - |
          objectName: database-password
          objectType: secret
```

## Authentication Methods

### 1. Azure CLI
```bash
az keyvault secret show --vault-name kv-dpn-azure-uks-01 --name database-password
```

### 2. Managed Identity (Recommended)
```bash
# Automatic with RBAC assignment
# No credentials needed
```

### 3. Service Principal
```bash
az login --service-principal \
  --username <app-id> \
  --password <password> \
  --tenant <tenant-id>
```

## Key Rotation

Keys with rotation enabled will automatically:
1. **Rotate** 30 days before expiry (configurable)
2. **Expire** after 90 days (configurable)
3. **Notify** 29 days before expiry (configurable)

## Monitoring

All operations logged to Log Analytics:
- **Audit Events** - All access attempts
- **Policy Evaluations** - Azure Policy compliance
- **Metrics** - Availability, latency, total requests

## Security Best Practices

1. ✅ **Always use RBAC** - More granular than access policies
2. ✅ **Enable purge protection** - Prevents accidental deletion
3. ✅ **Use private endpoints** - No public access
4. ✅ **Enable network ACLs** - Default deny policy
5. ✅ **Rotate keys regularly** - Use rotation policies
6. ✅ **Monitor access** - Review audit logs
7. ✅ **Use managed identities** - No credential storage
8. ✅ **Separate environments** - Different Key Vaults per environment

## Cost Optimization

- Use **standard SKU** unless HSM is required
- Set appropriate **soft delete retention** (7-90 days)
- Clean up unused **secrets and keys**
- Monitor **transaction costs** in Log Analytics

## Important Notes

- Key Vault names must be **3-24 characters**, alphanumerics and hyphens only
- Key Vault names must be **globally unique** (DNS name)
- Subnet `10.0.5.0/24` will be created - ensure no conflicts
- Public access disabled by default for security
- RBAC assignments require proper Azure AD permissions
- Initial secrets stored in OpenTofu state (use secure backend)
