# Log Analytics Workspace Module

## Purpose in this architecture

Central Log Analytics workspace. Every other module's diagnostic settings point here.

Unlike this codebase's other modules, this one does **not** deploy a private endpoint - see its own `main.tf` comment: Log Analytics is treated as secure by default (all traffic over HTTPS, access controlled via Azure RBAC, reached over the Azure backbone network), so no `privatelink.*` DNS zones or VNet links are created for it either.

## Features

- **Log Analytics Workspace** - `sku` and `retention_in_days` are both required inputs (no default), matching whatever the calling environment sets in `dpn_infrastructure.tfvars` (`PerGB2018` / `730` in the example)
- **System or User-Assigned identity** - via `identity_type`
- Own resource group (`azurerm_resource_group.log_analytics`)

## Usage

```hcl
module "loganalytics" {
  source = "../modules/loganalytics"

  log_analytics_workspace_name      = var.log_analytics_workspace_name
  log_analytics_resource_group_name = var.log_analytics_resource_group_name
  location                          = var.location
  sku                                = var.log_analytics_sku
  retention_in_days                 = var.log_analytics_retention_in_days
  identity_type                      = var.log_analytics_identity_type
  vnet_name                          = var.vnet_name
  vnet_resource_group_name           = var.vnet_resource_group_name
  connectivity_subscription_id       = var.connectivity_subscription_id
  private_dns_zone_resource_group    = var.private_dns_zone_resource_group
  tags                                = var.tags

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  depends_on = [module.networking]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `log_analytics_workspace_name` | Name of the Log Analytics Workspace | string | - | yes |
| `location` | Azure region | string | - | yes |
| `log_analytics_resource_group_name` | Resource group for Log Analytics (created by this module) | string | - | yes |
| `sku` | SKU for the workspace | string | - | yes |
| `retention_in_days` | Data retention in days (30-730) | number | - | yes |
| `identity_type` | Managed identity type for the workspace | string | - | yes |
| `vnet_name` | Existing VNet name | string | - | yes |
| `vnet_resource_group_name` | Resource group of the VNet | string | - | yes |
| `connectivity_subscription_id` | Subscription ID for the connectivity platform (Private DNS zones) | string | - | yes |
| `private_dns_zone_resource_group` | Resource group of the private DNS zones in the connectivity subscription | string | - | yes |
| `tags` | Resource tags | map(string) | - | yes |

## Outputs

- `log_analytics_workspace_id` - Resource ID of the workspace
- `log_analytics_workspace_name` - Name of the workspace
- `log_analytics_workspace_workspace_id` - Workspace GUID
- `log_analytics_workspace_primary_shared_key` - Primary shared key for the workspace (sensitive)

## Notes

- `vnet_name`, `vnet_resource_group_name`, `connectivity_subscription_id`, and `private_dns_zone_resource_group` are all required inputs, but this module doesn't use them to create anything - they only back a `data "azurerm_virtual_network" "existing_vnet"` lookup that nothing else in the module references. In practice this means `tofu plan` fails if the named VNet doesn't exist, even though no private endpoint or DNS wiring is actually created here. This is inherited from an earlier, private-endpoint version of this module; clean it up if you don't need the VNet-existence check.
- There is no `subnet_id` input and no `loganalytics` subnet requirement, despite what the root `dpn_infrastructure.tfvars` subnet map's naming might suggest for other modules.
