# Log Analytics Workspace with Private Link

## Purpose in this architecture

This is the central observability sink for the whole deployment - every other module's diagnostic settings (`enable_diagnostic_settings`) point here: AKS, Key Vault, ACR, storage, Event Grid, Service Bus, the VM, and Bastion all send their logs/metrics to this one workspace. If you're troubleshooting anything in this deployment - including the file-scanning pattern described in the root `README.md` - this is where to look first. Pair with `modules/ampls` if you need ingestion/query traffic itself to be private-only rather than just the resource being reachable privately.

This OpenTofu module deploys an Azure Log Analytics Workspace with Private Link connectivity using your existing VNet.

## Resources Created

1. **Log Analytics Workspace** - With 730 days retention
2. **Subnet** - `loganalytics` subnet (10.1.7.0/24) in your existing VNet
3. **Private Endpoint** - For secure connectivity to Log Analytics
4. **Private DNS Zones** - Required zones for Log Analytics private link:
   - `privatelink.monitor.azure.com`
   - `privatelink.oms.opinsights.azure.com`
   - `privatelink.ods.opinsights.azure.com`
   - `privatelink.agentsvc.azure-automation.net`
   - `privatelink.blob.core.windows.net`
5. **VNet Links** - Linking all DNS zones to your existing VNet

## Customer-Managed Key (CMK) Encryption

Not implemented in this module. Log Analytics CMK requires linking the workspace
to an `azurerm_log_analytics_cluster`, which carries its own minimum daily
capacity commitment (a fixed, non-trivial cost regardless of actual ingestion
volume) — this is a dedicated infrastructure decision, not a toggle on the
workspace itself, so it is not enabled by default here. If your compliance
requirements mandate CMK for logs, provision an `azurerm_log_analytics_cluster`
separately and link this workspace to it.

## Prerequisites

- Existing VNet in resource group `rg-dpn-dev-uks-01`
- The VNet must have available address space for subnet 10.1.7.0/24
- Appropriate Azure permissions to create resources

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `log_analytics_workspace_name` | Name of the Log Analytics Workspace | Required |
| `location` | Azure region | Required |
| `log_analytics_resource_group_name` | Resource group for Log Analytics | Required |
| `vnet_name` | Existing VNet name | `vnet-dpn-dev-uks-01` |
| `vnet_resource_group_name` | VNet resource group | `rg-dpn-dev-uks-01` |
| `tags` | Resource tags | Required |

## Usage Example

```hcl
module "log_analytics" {
  source = "./loganalytics"

  log_analytics_workspace_name      = "law-dpn-dev-uks-01"
  location                          = "UK South"
  log_analytics_resource_group_name = "rg-log-analytics-dev-uks-01"
  
  # These defaults match your existing VNet
  vnet_name                = "vnet-dpn-dev-uks-01"
  vnet_resource_group_name = "rg-dpn-dev-uks-01"

  tags = {
    Environment = "Development"
    Project     = "DPN"
    ManagedBy   = "OpenTofu"
  }
}
```

## Deployment Steps

1. **Initialize OpenTofu:**
   ```powershell
   tofu init
   ```

2. **Review the plan:**
   ```powershell
   tofu plan
   ```

3. **Apply the configuration:**
   ```powershell
   tofu apply
   ```

## Outputs

- `log_analytics_workspace_id` - Resource ID of the workspace
- `log_analytics_workspace_name` - Name of the workspace
- `log_analytics_workspace_workspace_id` - Workspace GUID
- `private_endpoint_id` - Private endpoint resource ID
- `private_endpoint_ip_address` - Private IP address
- `subnet_id` - Log Analytics subnet ID

## Network Connectivity

All traffic to Log Analytics will route through the private endpoint in subnet `10.1.7.0/24`. The private DNS zones ensure that Log Analytics API calls resolve to private IP addresses within your VNet.

## Important Notes

- The subnet `10.1.7.0/24` will be created in your existing VNet
- Ensure this address range doesn't conflict with existing subnets
- Private Link requires specific DNS zones for full functionality
- All resources will be tagged as specified
