# Azure Container Registry (ACR) Module

## Purpose in this architecture

Private Azure Container Registry for your application's container images. AKS's cluster and kubelet identities are automatically granted pull access; any other cluster's managed identity that also needs to pull from here can be added via `aks_external_acr_pull_principal_ids` in the root config.

This module deploys an enterprise-grade Azure Container Registry with private endpoint connectivity, zone redundancy, geo-replication, and comprehensive security features.

## Features

### Security & Compliance
- **Private Endpoint** - Secure access via VNet, no public exposure
- **Network Rules** - IP filtering and default deny policy
- **Azure AD Integration** - Managed identity authentication
- **Customer-Managed Keys** - Encryption with your own keys (Premium)
- **Admin Account** - Disabled by default (use managed identities)
- **Audit Logging** - All operations logged to Log Analytics

### High Availability
- **Zone Redundancy** - Spread across availability zones (Premium)
- **Geo-Replication** - Multi-region replication for DR (Premium)
- **99.95% SLA** - With Premium SKU and zone redundancy

### Operations
- **Retention Policy** - Auto-cleanup of untagged manifests (Premium)
- **Webhooks** - Event notifications for CI/CD integration
- **Scope Maps** - Token-based access control
- **Diagnostic Logs** - Repository events, login events, metrics

### Networking
- **Private DNS Zone** - `privatelink.azurecr.io` with VNet linking
- **Dedicated Subnet** - `acr` subnet (10.0.10.0/24)
- **Private Endpoint** - Single subresource: `registry`

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  VNet: vnet-dpn-azure-uks-01 (10.0.0.0/16)           │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ acr subnet (10.0.10.0/24)                    │  │
│  │   └─ ACR Private Endpoint                    │  │
│  │      - privatelink.azurecr.io                │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ aks subnet (10.0.2.0/24)                    │  │
│  │   └─ AKS Cluster                             │  │
│  │      - Pulls images via private endpoint     │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘

ACR (Premium, Zone-Redundant)
├─ Private Endpoint (VNet Only)
├─ Geo-Replicas (Optional)
├─ Retention Policy (7 days)
```

## Usage

### Minimum Configuration

```hcl
module "acr" {
  source = "./container_registry"

  acr_name                              = "acrdpnazureuks01"  # Must be globally unique, alphanumeric only
  location                              = "UK South"
  resource_group_name                   = "rg-acr-dpn-azure-uks-01"
  
  # Premium SKU for private endpoints and zone redundancy
  sku                                   = "Premium"
  zone_redundancy_enabled               = true
  public_network_access_enabled         = false
  
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
  }
}
```

### Full Configuration with All Features

```hcl
module "acr" {
  source = "./container_registry"

  acr_name                              = "acrdpnazureuks01"
  location                              = "UK South"
  resource_group_name                   = "rg-acr-dpn-azure-uks-01"
  
  # SKU and redundancy
  sku                                   = "Premium"
  zone_redundancy_enabled               = true
  public_network_access_enabled         = false
  
  # Network security
  network_rules_enabled                 = true
  network_rule_default_action           = "Deny"
  allowed_ip_ranges                     = []  # Empty = deny all public access
  
  # Retention and trust policies
  retention_policy_enabled              = true
  retention_policy_days                 = 7
  trust_policy_enabled                  = true
  
  # Customer-managed encryption (optional)
  encryption_enabled                    = false
  key_vault_key_id                      = null
  
  # Geo-replication for disaster recovery
  georeplications = {
    "northeurope" = {
      location                  = "North Europe"
      zone_redundancy_enabled   = true
      regional_endpoint_enabled = false
    }
  }
  
  # Scope maps for token authentication
  create_scope_maps                     = true
  
  # Webhooks for CI/CD
  webhooks = {
    "cicd-webhook" = {
      service_uri    = "https://your-cicd-system.com/webhook"
      status         = "enabled"
      scope          = ""
      actions        = ["push", "delete"]
      custom_headers = {}
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
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `acr_name` | ACR name (globally unique, alphanumeric) | string | - | yes |
| `location` | Azure region | string | - | yes |
| `resource_group_name` | Resource group name | string | - | yes |
| `sku` | SKU (Basic/Standard/Premium) | string | `Premium` | no |
| `zone_redundancy_enabled` | Enable zone redundancy (Premium) | bool | `true` | no |
| `public_network_access_enabled` | Allow public access | bool | `false` | no |
| `admin_enabled` | Enable admin account | bool | `false` | no |
| `anonymous_pull_enabled` | Allow anonymous pulls | bool | `false` | no |
| `vnet_name` | Existing VNet name | string | `vnet-dpn-azure-uks-01` | no |
| `vnet_resource_group_name` | VNet resource group | string | `rg-dpn-azure-uks-01` | no |
| `network_rules_enabled` | Enable network rules | bool | `true` | no |
| `network_rule_default_action` | Default action (Allow/Deny) | string | `Deny` | no |
| `allowed_ip_ranges` | Allowed IP ranges | list(string) | `[]` | no |
| `retention_policy_enabled` | Auto-cleanup untagged (Premium) | bool | `true` | no |
| `retention_policy_days` | Retention days (0-365) | number | `7` | no |
| `trust_policy_enabled` | Accepted but not wired to any resource attribute - has no effect. Docker Content Trust is deprecated by Azure for ACR; see Image Signing below | bool | `false` | no |
| `encryption_enabled` | Customer-managed keys (Premium) | bool | `false` | no |
| `key_vault_key_id` | Key Vault key ID | string | `null` | no |
| `georeplications` | Geo-replication config (Premium) | map(object) | `{}` | no |
| `create_scope_maps` | Create default scope maps | bool | `false` | no |
| `webhooks` | Webhook configurations | map(object) | `{}` | no |
| `log_analytics_workspace_name` | Log Analytics workspace | string | - | yes |
| `log_analytics_resource_group_name` | Log Analytics RG | string | - | yes |
| `tags` | Resource tags | map(string) | - | yes |

## Outputs

- `acr_id` - ACR resource ID
- `acr_name` - ACR name
- `acr_login_server` - Login server URL (e.g., `acrdpnazureuks01.azurecr.io`)
- `acr_admin_username` - Admin username (if enabled)
- `acr_admin_password` - Admin password (sensitive, if enabled)
- `private_endpoint_id` - Private endpoint ID
- `private_endpoint_ip_address` - Private IP address
- `acr_subnet_id` - ACR subnet ID
- `private_dns_zone_id` - Private DNS zone ID
- `user_assigned_identity_id` - Managed identity ID (if encryption enabled)

## SKU Comparison

| Feature | Basic | Standard | Premium |
|---------|-------|----------|---------|
| Private Endpoint | ❌ | ❌ | ✅ |
| Zone Redundancy | ❌ | ❌ | ✅ |
| Geo-Replication | ❌ | ❌ | ✅ |
| Customer Keys | ❌ | ❌ | ✅ |
| Retention Policy | ❌ | ❌ | ✅ |
| Webhooks | ✅ | ✅ | ✅ |
| Storage | 10 GB | 100 GB | 500 GB |
| Throughput | Low | Medium | High |

**For production with VNet integration, Premium SKU is required.**

## Authentication Methods

### 1. Managed Identity (Recommended)
```bash
# AKS automatically uses managed identity
# No credentials needed - configured via OpenTofu
```

### 2. Azure CLI
```bash
az acr login --name acrdpnazureuks01
```

### 3. Docker Login with Managed Identity
```bash
TOKEN=$(az acr login --name acrdpnazureuks01 --expose-token --output tsv --query accessToken)
echo $TOKEN | docker login acrdpnazureuks01.azurecr.io -u 00000000-0000-0000-0000-000000000000 --password-stdin
```

### 4. Scope Map Tokens (if created)
```bash
# Create token from scope map
az acr token create --name my-token --registry acrdpnazureuks01 --scope-map pull-scope
```

## Using with AKS

The ACR is automatically accessible from AKS when:
1. Both are in the same VNet or peered VNets
2. AKS has `AcrPull` role assigned (configured in AKS module)
3. Private endpoint DNS resolves correctly

```bash
# Pull image in AKS pod
docker pull acrdpnazureuks01.azurecr.io/myapp:v1.0
```

## Image Signing

Docker Content Trust is deprecated by Azure for ACR and is not configurable through this module. To enforce that only signed images can be pulled/deployed, use Azure Policy with Notation/Ratify instead - that's a policy-level control, not a Terraform setting on the registry itself. This codebase already provisions the Ratify workload identity and a Notation signing certificate for that purpose - see `modules/workload_identity`'s `ratify_identity` block and `keyvault_initial_certificates` in the root config.

## Retention Policy

Untagged manifests are automatically deleted after 7 days (configurable). This keeps the registry clean and reduces costs.

## Geo-Replication

Replicate images to multiple regions for:
- **Lower latency** - Pull from nearest region
- **Disaster recovery** - Automatic failover
- **Compliance** - Data residency requirements

## Monitoring

All logs are sent to Log Analytics:
- **Repository Events** - Push, pull, delete
- **Login Events** - Authentication attempts
- **Metrics** - Storage, requests, throughput

## Cost Optimization

- Use **Standard SKU** if private endpoints aren't needed
- Disable **geo-replication** in non-prod environments
- Enable **retention policy** to auto-cleanup old images
- Use **lifecycle policies** to delete old tags

## Important Notes

- ACR names must be **globally unique** and **alphanumeric only**
- Premium SKU required for private endpoints, zone redundancy, geo-replication
- Subnet `10.0.10.0/24` will be created - ensure no conflicts
- Public access disabled by default for security
- Admin account disabled - use managed identities
