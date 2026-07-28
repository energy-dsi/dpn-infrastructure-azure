# Azure Monitor Private Link Scope (AMPLS) Module

This module deploys an Azure Monitor Private Link Scope and links it to an existing Log Analytics workspace, forcing all ingestion and query traffic for that workspace through a private endpoint instead of the public Azure Monitor endpoints. This is the mechanism used to fully privatize Log Analytics access in the air-gapped DPN environments.

> **Status:** Not currently wired into any environment's `main.tf` — the `module "ampls"` block in each `dpn-airgap-azure-<env>/main.tf` is present but commented out.

## Features

- **Private-only ingestion** – `ingestion_access_mode = "PrivateOnly"` on the Private Link Scope
- **Private-only query** – `query_access_mode = "PrivateOnly"` on the Private Link Scope
- **Scoped resource linking** – links a single Log Analytics workspace into the scope via `azurerm_monitor_private_link_scoped_service`
- **Private Endpoint** – single private endpoint with subresource `azuremonitor`
- **Dual DNS zone group** – supports linking both the `ods` and `oms` opinsights private DNS zones to the same private endpoint (either can be omitted; `compact()` drops nulls)

## Architecture

```
┌───────────────────────────────────────────────────────────────┐
│  VNet (existing)                                              │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐    │
│  │ ampls subnet                                           │    │
│  │   └─ Private Endpoint (subresource: azuremonitor)      │    │
│  │        ├─ privatelink.ods.opinsights.azure.com         │    │
│  │        └─ privatelink.oms.opinsights.azure.com         │    │
│  └───────────────────────────────────────────────────────┘    │
│                          │                                     │
│                          ▼                                     │
│              Azure Monitor Private Link Scope                 │
│                          │                                     │
│                          ▼                                     │
│              Log Analytics Workspace (module.loganalytics)     │
└───────────────────────────────────────────────────────────────┘
```

## Usage

```hcl
module "ampls" {
  source = "../modules/ampls"

  workspace_name             = var.log_analytics_workspace_name
  resource_group_name        = var.log_analytics_resource_group_name
  location                   = var.location
  log_analytics_workspace_id = module.loganalytics.log_analytics_workspace_id
  subnet_id                  = module.networking.subnet_ids["snet-dpn-azure-${var.environment}-${var.location_short}-ampls"]

  ods_private_dns_zone_id = "/subscriptions/${var.private_dns_zone_subscription_id}/resourceGroups/${var.private_dns_zone_resource_group}/providers/Microsoft.Network/privateDnsZones/privatelink.ods.opinsights.azure.com"
  oms_private_dns_zone_id = "/subscriptions/${var.private_dns_zone_subscription_id}/resourceGroups/${var.private_dns_zone_resource_group}/providers/Microsoft.Network/privateDnsZones/privatelink.oms.opinsights.azure.com"

  tags = var.tags

  providers  = { azurerm = azurerm }
  depends_on = [module.networking, module.loganalytics]
}
```

Note that the private DNS zones may live in a different subscription than the one this module deploys into, so they're referenced here by full resource ID string rather than a data source lookup - this module only declares the default `azurerm` provider.

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `workspace_name` | Name of the Log Analytics workspace (used for AMPLS/PE resource naming) | `string` | - | yes |
| `resource_group_name` | Resource group for AMPLS resources (same RG as the Log Analytics workspace) | `string` | - | yes |
| `location` | Azure region | `string` | - | yes |
| `log_analytics_workspace_id` | Resource ID of the Log Analytics workspace to link into AMPLS | `string` | - | yes |
| `subnet_id` | Subnet ID for the AMPLS private endpoint | `string` | - | yes |
| `ods_private_dns_zone_id` | Full ARM resource ID of the `privatelink.ods.opinsights.azure.com` zone | `string` | `null` | no |
| `oms_private_dns_zone_id` | Full ARM resource ID of the `privatelink.oms.opinsights.azure.com` zone | `string` | `null` | no |
| `tags` | Tags to apply to all resources | `map(string)` | - | yes |

## Outputs

This module currently defines **no outputs** (no `outputs.tf`).

## Resources Created

- `azurerm_monitor_private_link_scope.ampls` — named `ampls-<workspace_name>`
- `azurerm_monitor_private_link_scoped_service.law` — named `ampls-law-link`, linking the Log Analytics workspace into the scope
- `azurerm_private_endpoint.ampls` — named `<workspace_name>-ampls-pe`, private service connection `<workspace_name>-ampls-psc`, subresource `azuremonitor`

## Important Notes

- Both `ods_private_dns_zone_id` and `oms_private_dns_zone_id` default to `null`; if both are omitted no `private_dns_zone_group` block is created (the `compact()` call filters out nulls), meaning DNS records won't be auto-registered and the endpoint will need manual DNS management.
- `azurerm_monitor_private_link_scoped_service.law` must complete before the private endpoint is created — enforced via an explicit `depends_on`.
- Enabling this module makes the linked Log Analytics workspace's ingestion and query **private-only**; any other resource in the environment that queries the same workspace over the public endpoint will need network line-of-sight to this private endpoint.
