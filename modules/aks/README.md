# Azure Kubernetes Service (AKS) Module

## Purpose in this architecture

This is the compute layer - a private AKS cluster that runs your application. It comes with a system node pool (AKS-managed components only), an optional workload node pool for your containers, the Key Vault CSI driver for secret injection, and workload identity federation via its OIDC issuer (see `modules/workload_identity`).

This module deploys a production-ready Azure Kubernetes Service cluster with private cluster configuration, Azure Container Registry integration, and Key Vault secrets provider.

## Features

### Security
- **Private Cluster** - API server accessible only via private endpoint (configurable)
- **Azure AD Integration** - RBAC with Azure AD groups
- **Workload Identity** - OIDC issuer enabled for pod identity
- **Host Encryption** - Enabled on all node pools
- **Local Accounts Disabled** - AAD-only authentication
- **Azure Policy** - Enabled for governance

### Networking
- **Azure CNI with Overlay** - Efficient IP management
- **Calico Network Policy** - Pod-level network security
- **Multi-zone Deployment** - High availability across zones 1, 2, 3
- **Private DNS Zone Integration** - For private cluster resolution

### Monitoring & Operations
- **Log Analytics Integration** - OMS agent configured
- **Diagnostic Settings** - All logs and metrics sent to Log Analytics
- **Service Mesh** - Istio service mesh pre-configured

### Key Integrations
- **Azure Container Registry** - Automatic pull permissions for AKS and kubelet identities
- **Key Vault Secrets Provider** - CSI driver with 2-minute secret rotation
- **Network Contributor** - Role assigned for subnet operations

### Node Pools
- **Default Pool** - System workloads with configurable size and count
- **Workload Pool** - Optional additional pool for application workloads with custom taints

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `resource_group_name` | Resource group name | string | - | yes |
| `location` | Azure region | string | `UKSouth` | no |
| `aks_name` | AKS cluster name | string | - | yes |
| `private_cluster_enabled` | Enable private cluster | bool | `true` | no |
| `private_dns_zone_id` | Private DNS zone resource ID | string | `null` | conditional |
| `sku_tier` | AKS SKU tier (Free/Standard/Premium) | string | `Standard` | no |
| `automatic_upgrade_channel` | Upgrade channel (patch/rapid/node-image/stable) | string | `stable` | no |
| `node_os_upgrade_channel` | Node OS upgrade channel | string | `NodeImage` | no |
| `vm_size` | Default node pool VM size | string | `Standard_DS2_v2` | no |
| `node_count` | Default node pool count | number | `3` | no |
| `vnet_subnet_name` | AKS subnet name | string | - | yes |
| `vnet_resource_group_name` | VNet resource group | string | - | yes |
| `vnet_name` | VNet name | string | - | yes |
| `aks_admin_group` | Azure AD admin group object IDs | list(string) | `[]` | no |
| `log_analytics_workspace_name` | Log Analytics workspace name | string | - | yes |
| `log_analytics_resource_group_name` | Log Analytics resource group | string | - | yes |
| `service_cidr` | Kubernetes service CIDR | string | - | yes |
| `dns_service_ip` | Kubernetes DNS service IP | string | - | yes |
| `enable_workload_node_pool` | Enable additional workload pool | bool | `false` | no |
| `workload_node_pool_vm_size` | Workload pool VM size | string | `Standard_D4s_v5` | no |
| `workload_node_pool_count` | Workload pool node count | number | `3` | no |
| `workload_node_pool_taints` | Workload pool taints | list(string) | `[]` | no |
| `container_registry_id` | ACR resource ID for integration | string | `null` | no |
| `key_vault_id` | Key Vault resource ID for secrets | string | `null` | no |
| `tags` | Resource tags | map(string) | - | yes |

## Usage Example

```hcl
module "aks" {
  source = "./aks"

  resource_group_name = "rg-aks-dpn-azure-uks-01"
  location            = "UK South"
  aks_name            = "aks-dpn-azure-uks-01"
  
  # Private cluster configuration
  private_cluster_enabled = true
  private_dns_zone_id     = "/subscriptions/xxx/resourceGroups/rg-dpn-azure-uks-01/providers/Microsoft.Network/privateDnsZones/privatelink.uksouth.azmk8s.io"
  
  # Upgrade configuration
  sku_tier                 = "Standard"
  automatic_upgrade_channel = "stable"
  node_os_upgrade_channel  = "NodeImage"
  
  # Networking
  vnet_name                = "vnet-dpn-azure-uks-01"
  vnet_resource_group_name = "rg-dpn-azure-uks-01"
  vnet_subnet_name         = "aks"
  service_cidr             = "172.16.0.0/16"
  dns_service_ip           = "172.16.0.10"
  
  # Node pools
  vm_size    = "Standard_D4s_v5"
  node_count = 3
  
  # Optional workload pool
  enable_workload_node_pool   = true
  workload_node_pool_vm_size  = "Standard_D8s_v5"
  workload_node_pool_count    = 3
  workload_node_pool_taints   = ["workload=true:NoSchedule"]
  
  # Integrations
  container_registry_id = "/subscriptions/xxx/resourceGroups/rg-acr-dpn-azure-uks-01/providers/Microsoft.ContainerRegistry/registries/acrdpnazureuks01"
  key_vault_id          = "/subscriptions/xxx/resourceGroups/rg-kv-dpn-azure-uks-01/providers/Microsoft.KeyVault/vaults/kv-dpn-azure-uks-01"
  
  # RBAC
  aks_admin_group = ["xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]
  
  # Monitoring
  log_analytics_workspace_name      = "law-dpn-azure-uks-01"
  log_analytics_resource_group_name = "rg-law-dpn-azure-uks-01"
  
  tags = {
    Environment = "Development"
    Project     = "DPN"
    ManagedBy   = "OpenTofu"
  }
}
```

## Outputs

- `aks` - Complete AKS cluster object
- `aks_id` - AKS cluster resource ID
- `aks_name` - AKS cluster name
- `aks_fqdn` - Public FQDN
- `aks_private_fqdn` - Private FQDN (when private cluster enabled)
- `aks_principal_id` - System managed identity principal ID
- `aks_kubelet_identity` - Kubelet identity object ID
- `aks_oidc_issuer_url` - OIDC issuer URL for workload identity
- `key_vault_secrets_provider_identity` - Key Vault CSI identity

## Prerequisites

1. **Existing VNet** with AKS subnet in `rg-dpn-azure-uks-01`
2. **Private DNS Zone** for AKS (if using private cluster)
3. **Log Analytics Workspace** for monitoring
4. **Azure AD Group** for AKS administrators
5. **(Optional)** Azure Container Registry
6. **(Optional)** Azure Key Vault

## Private Cluster Setup

For private cluster deployment, you need to create the private DNS zone first:

```bash
# DNS zone format: privatelink.<region>.azmk8s.io
# For UK South: privatelink.uksouth.azmk8s.io
```

## Post-Deployment

After deployment, connect to the cluster:

```bash
# Get credentials
az aks get-credentials --resource-group rg-aks-dpn-azure-uks-01 --name aks-dpn-azure-uks-01

# Verify connection
kubectl get nodes
```

## Key Vault Integration

To use Key Vault secrets in pods:

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
    - name: secrets
      mountPath: "/mnt/secrets"
      readOnly: true
  volumes:
  - name: secrets
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: "azure-kv-secrets"
```

## Important Notes

- Default SKU tier is **Standard** (SLA-backed)
- Private cluster requires DNS zone in same subscription or proper linking
- ACR integration grants **AcrPull** role to both cluster and kubelet identities
- Key Vault secrets rotate every 2 minutes by default
- Workload node pool is optional and disabled by default
