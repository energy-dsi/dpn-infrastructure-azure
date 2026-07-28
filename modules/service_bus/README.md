# Service Bus Namespace Module

## Purpose in this architecture

This module deploys a private Azure Service Bus namespace with a private endpoint, optional queues, role-based data-plane access, and diagnostic settings.

In this reference architecture it exists as the decoupling layer for the file-scanning pattern described in the root `README.md`: an Event Grid subscription (see `modules/event_grid`) forwards Microsoft Defender for Storage malware-scan-result events here, and a consumer application (outside this codebase) reads them from a queue to decide whether a scanned file is safe to move to its destination. Using a queue in front of the consumer means a burst of scan events, or the consumer being temporarily down, doesn't lose or drop any results.

**Note on "queue" vs "topic":** this module only creates `azurerm_servicebus_queue` resources (single-consumer semantics), not `azurerm_servicebus_topic`/subscriptions (pub-sub fan-out to multiple independent consumers). For the file-scanning pattern - one consumer processing scan results - a queue is sufficient. If your use case needs multiple independent consumers each processing every message, you'll need to extend this module with topic/subscription resources.

If your workload doesn't need this pattern, this module is still usable standalone for any private Service Bus namespace/queue need.

## Features

### Namespace & Network
- **Own Resource Group** – the module creates `azurerm_resource_group.service_bus` rather than deploying into an existing one
- **SKU validation** – `sku` must be `Basic`, `Standard`, or `Premium` (default `Premium`, required for private endpoints); `capacity` and `premium_messaging_partitions` only apply on Premium
- **Private Endpoint** – subresource `namespace`, with an optional `private_dns_zone_group` (only created when `private_dns_zone_id` is non-null/non-empty)
- **Network Rule Set** – `default_action = "Allow"` at the network-rule level (required by the provider when no IP/network rules are configured); `public_network_access_enabled` (all 4 DPN environments set this `true`) controls whether the public endpoint is reachable at all, alongside the private endpoint — no IP restriction is currently configured, so add `ip_rules` if the public path needs scoping down; `trusted_services_allowed` (default `true`) lets Microsoft trusted services bypass
- **TLS enforcement** – `minimum_tls_version` (default `1.2`)
- **Local auth toggle** – `local_auth_enabled` (default `false`) to disable SAS-key authentication

### Queues
- **Dynamic queue creation** – `azurerm_servicebus_queue` for each entry in the `queues` map, with per-queue optional attributes (`max_size_in_megabytes`, `default_message_ttl`, `lock_duration`, `dead_lettering_on_message_expiration`, `max_delivery_count`, `requires_duplicate_detection`, `requires_session`, `partitioning_enabled`)

### RBAC
- **Azure Service Bus Data Receiver** – granted per-principal via `data_receiver_principal_ids`
- **Azure Service Bus Data Sender** – granted per-principal via `data_sender_principal_ids`
- **Azure Service Bus Data Owner** – granted per-principal via `data_owner_principal_ids`

### Monitoring
- **Diagnostic Setting** – `OperationalLogs`, `VNetAndIPFilteringLogs`, `RuntimeAuditLogs`, and `AllMetrics` sent to Log Analytics, toggled by `enable_diagnostic_settings` (default `true`)

## Architecture

```
┌───────────────────────────────────────────────────────────────┐
│  rg-service-bus (module-managed resource group)                │
│                                                                  │
│   Service Bus Namespace (Premium)                              │
│     ├─ Private Endpoint (subresource: namespace)                │
│     │     └─ privatelink.servicebus.windows.net (shared DNS) │
│     ├─ Queues (for_each var.queues)                             │
│     ├─ RBAC: Data Receiver / Data Sender / Data Owner           │
│     └─ Diagnostic Setting → Log Analytics                       │
│           (OperationalLogs, VNetAndIPFilteringLogs,             │
│            RuntimeAuditLogs, AllMetrics)                        │
└───────────────────────────────────────────────────────────────┘
```

## Usage

```hcl
module "service_bus" {
  source = "../modules/service_bus"

  namespace_name                = var.service_bus_namespace_name
  resource_group_name           = var.service_bus_resource_group_name
  location                      = var.location
  sku                           = var.service_bus_sku
  capacity                      = var.service_bus_capacity
  premium_messaging_partitions  = var.service_bus_premium_messaging_partitions
  public_network_access_enabled = var.service_bus_public_network_access_enabled
  local_auth_enabled            = var.service_bus_local_auth_enabled
  trusted_services_allowed      = var.service_bus_trusted_services_allowed
  minimum_tls_version           = var.service_bus_minimum_tls_version
  subnet_id                     = module.networking.subnet_ids[var.service_bus_subnet_name]
  private_dns_zone_id           = "/subscriptions/${var.private_dns_zone_subscription_id}/resourceGroups/${var.private_dns_zone_resource_group}/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net"
  queues                        = var.service_bus_queues
  data_receiver_principal_ids   = var.service_bus_data_receiver_principal_ids
  data_sender_principal_ids     = var.service_bus_data_sender_principal_ids
  data_owner_principal_ids      = var.service_bus_data_owner_principal_ids
  enable_diagnostic_settings    = var.service_bus_enable_diagnostic_settings
  log_analytics_workspace_id    = module.loganalytics.log_analytics_workspace_id
  tags                          = var.tags

  providers  = { azurerm = azurerm }
  depends_on = [module.networking, module.loganalytics]
}
```

### Queue configuration example

```hcl
service_bus_queues = {
  "orders" = {
    max_size_in_megabytes = 2048
    max_delivery_count    = 5
    requires_session      = true
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `namespace_name` | Name of the Service Bus namespace | `string` | - | yes |
| `resource_group_name` | Name of the resource group (created by this module) | `string` | - | yes |
| `location` | Azure region | `string` | - | yes |
| `sku` | SKU (`Basic`/`Standard`/`Premium`); Premium required for private endpoints | `string` | `Premium` | no |
| `capacity` | Messaging units for Premium tier (1, 2, 4, 8, or 16) | `number` | `1` | no |
| `premium_messaging_partitions` | Number of messaging partitions for Premium tier (1, 2, or 4) | `number` | `1` | no |
| `public_network_access_enabled` | Enable public network access | `bool` | `false` | no |
| `local_auth_enabled` | Enable SAS-token local authentication | `bool` | `false` | no |
| `trusted_services_allowed` | Allow trusted Microsoft services to bypass network rules | `bool` | `true` | no |
| `minimum_tls_version` | Minimum TLS version | `string` | `1.2` | no |
| `subnet_id` | Subnet ID for the private endpoint | `string` | - | yes |
| `private_dns_zone_id` | Full ARM resource ID of the `privatelink.servicebus.windows.net` zone | `string` | `null` | no |
| `queues` | Map of Service Bus queues to create (see optional per-queue attributes above) | `map(object)` | `{}` | no |
| `data_receiver_principal_ids` | Principal IDs granted `Azure Service Bus Data Receiver` | `list(string)` | `[]` | no |
| `data_sender_principal_ids` | Principal IDs granted `Azure Service Bus Data Sender` | `list(string)` | `[]` | no |
| `data_owner_principal_ids` | Principal IDs granted `Azure Service Bus Data Owner` | `list(string)` | `[]` | no |
| `enable_diagnostic_settings` | Enable diagnostic settings | `bool` | `true` | no |
| `log_analytics_workspace_id` | Log Analytics workspace ID for diagnostic settings | `string` | - | yes |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

- `namespace_id` - Resource ID of the Service Bus namespace
- `namespace_name` - Name of the Service Bus namespace
- `resource_group_name` - Name of the resource group created by this module
- `queue_ids` - Map of queue names to resource IDs

## Customer-Managed Key (CMK) Encryption

Set `encryption_enabled = true` plus `key_vault_key_id` and `key_vault_id` to
encrypt this namespace with your own Key Vault key instead of a
Microsoft-managed key. Requires `sku = "Premium"` (Azure platform
requirement) — the module creates its own user-assigned identity and grants
it `Key Vault Crypto Service Encryption User` on `key_vault_id`.

## Important Notes

- `capacity` and `premium_messaging_partitions` are silently ignored (passed as `null`) unless `sku = "Premium"`.
- The `network_rule_set` block's `default_action` is hard-coded to `Allow` because the AzureRM provider rejects `Deny` when no `ip_rules`/`network_rules` are configured — actual lockdown comes from `public_network_access_enabled = false`, not the network rule set.
- The module creates its own resource group — do not point `resource_group_name` at a resource group managed elsewhere.
