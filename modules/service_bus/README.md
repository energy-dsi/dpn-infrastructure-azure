# Service Bus Namespace Module

## Purpose in this architecture

This module deploys a private Azure Service Bus namespace with a private endpoint, optional queues, role-based data-plane access, and diagnostic settings.

In this reference architecture it exists as the decoupling layer for the file-scanning pattern described in the root `README.md`: an Event Grid subscription (see `modules/event_grid`) forwards Microsoft Defender for Storage malware-scan-result events here, and a consumer application (outside this codebase) reads them from a queue to decide whether a scanned file is safe to move to its destination. Using a queue in front of the consumer means a burst of scan events, or the consumer being temporarily down, doesn't lose or drop any results.

**Note on "queue" vs "topic":** this module only creates `azurerm_servicebus_queue` resources (single-consumer semantics), not `azurerm_servicebus_topic`/subscriptions (pub-sub fan-out to multiple independent consumers). For the file-scanning pattern - one consumer processing scan results - a queue is sufficient. If your use case needs multiple independent consumers each processing every message, you'll need to extend this module with topic/subscription resources.

If your workload doesn't need this pattern, this module is still usable standalone for any private Service Bus namespace/queue need.

## Features

### Namespace & Network
- **Own Resource Group** - the module creates `azurerm_resource_group.service_bus` rather than deploying into an existing one; both the resource group and the namespace have `lifecycle { prevent_destroy = true }`
- **SKU** - `sku` defaults to `Premium` (required for private endpoints); `capacity` and `premium_messaging_partitions` are passed through regardless of SKU
- **Private Endpoint** - single subresource `namespace`, named `pe-<namespace_name>`
- **Network Rule Set** - a `dynamic "network_rule_set"` block is only added when `trusted_services_allowed = true` (default `false`); when present it sets `public_network_access_enabled = false` and `trusted_services_allowed = true` inside the network rule set itself, layered on top of the namespace-level `public_network_access_enabled` variable
- **TLS enforcement** - `minimum_tls_version` (default `1.2`)
- **Local auth toggle** - `local_auth_enabled` (default `false`) to disable SAS-key authentication
- **System-assigned managed identity** on the namespace

### Queues
- **Dynamic queue creation** - `azurerm_servicebus_queue` for each entry in the `queues` map, with three optional per-queue attributes: `max_size_in_megabytes` (default `1024`), `default_message_ttl` (default `P14D`), `lock_duration` (default `PT1M`)

### RBAC
- **Azure Service Bus Data Receiver** - granted per-principal via `data_receiver_principal_ids`
- **Azure Service Bus Data Sender** - granted per-principal via `data_sender_principal_ids`
- **Azure Service Bus Data Owner** - granted per-principal via `data_owner_principal_ids`

### Monitoring
- **Diagnostic Setting** - `allLogs` category group plus `AllMetrics`, sent to Log Analytics, toggled by `enable_diagnostic_settings` (default `true`)

```
┌──────────────────────────────────────────────────────────────────┐
│  Resource Group (module-managed, prevent_destroy)                 │
│                                                                      │
│   Service Bus Namespace (default SKU: Premium, prevent_destroy)    │
│     ├─ Private Endpoint (pe-<namespace_name>, subresource: namespace) │
│     ├─ Queues (for_each var.queues)                                 │
│     ├─ RBAC: Data Receiver / Data Sender / Data Owner               │
│     └─ Diagnostic Setting → Log Analytics (allLogs, AllMetrics)     │
└──────────────────────────────────────────────────────────────────┘
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
  minimum_tls_version           = var.service_bus_minimum_tls_version
  local_auth_enabled            = var.service_bus_local_auth_enabled
  trusted_services_allowed      = var.service_bus_trusted_services_allowed
  subnet_id                     = module.networking.subnet_ids[var.service_bus_subnet_name]
  queues                        = var.service_bus_queues
  data_receiver_principal_ids   = var.service_bus_data_receiver_principal_ids
  data_sender_principal_ids     = var.service_bus_data_sender_principal_ids
  data_owner_principal_ids      = var.service_bus_data_owner_principal_ids
  enable_diagnostic_settings    = var.service_bus_enable_diagnostic_settings
  log_analytics_workspace_id    = module.loganalytics.log_analytics_workspace_id
  tags                          = var.tags

  depends_on = [module.networking, module.loganalytics]
}
```

## Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `namespace_name` | Name of the Service Bus namespace | `string` | - | yes |
| `resource_group_name` | Name of the resource group (created by this module) | `string` | - | yes |
| `location` | Azure region | `string` | - | yes |
| `sku` | SKU (`Basic`/`Standard`/`Premium`); Premium required for private endpoints | `string` | `Premium` | no |
| `capacity` | Messaging units for Premium tier (1, 2, 4, 8, or 16) | `number` | `1` | no |
| `premium_messaging_partitions` | Number of messaging partitions for Premium tier (0, 1, or 2) | `number` | `1` | no |
| `public_network_access_enabled` | Enable public network access | `bool` | `false` | no |
| `local_auth_enabled` | Enable SAS-token local authentication | `bool` | `false` | no |
| `trusted_services_allowed` | Allow trusted Microsoft services to bypass network rules | `bool` | `false` | no |
| `minimum_tls_version` | Minimum TLS version | `string` | `1.2` | no |
| `subnet_id` | Subnet ID for the private endpoint | `string` | - | yes |
| `queues` | Map of Service Bus queues to create (see optional per-queue attributes above) | `map(object)` | `{}` | no |
| `data_receiver_principal_ids` | Principal IDs granted `Azure Service Bus Data Receiver` | `list(string)` | `[]` | no |
| `data_sender_principal_ids` | Principal IDs granted `Azure Service Bus Data Sender` | `list(string)` | `[]` | no |
| `data_owner_principal_ids` | Principal IDs granted `Azure Service Bus Data Owner` | `list(string)` | `[]` | no |
| `enable_diagnostic_settings` | Enable diagnostic settings | `bool` | `true` | no |
| `log_analytics_workspace_id` | Log Analytics workspace ID for diagnostic settings | `string` | `null` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

- `namespace_id` - Resource ID of the Service Bus namespace
- `namespace_name` - Name of the Service Bus namespace

## Customer-Managed Key (CMK) Encryption

Set `encryption_enabled = true` plus `key_vault_key_id` and `key_vault_id` to encrypt this namespace with your own Key Vault key instead of a Microsoft-managed one. Requires `sku = "Premium"` (Azure platform requirement) - the module creates its own user-assigned identity and grants it `Key Vault Crypto Service Encryption User` on `key_vault_id`.

## Notes

- The namespace's `identity` block is now a `dynamic` block: `SystemAssigned` alone normally, `"SystemAssigned, UserAssigned"` (with the CMK identity attached) when `encryption_enabled = true`.
- This module creates its own resource group, and both the resource group and namespace have `prevent_destroy = true` - to actually destroy this namespace, remove that lifecycle block first.
- The `network_rule_set` block is only present when `trusted_services_allowed = true`; leaving it at the default `false` means no network rule set is configured at all, and public access is governed solely by `public_network_access_enabled`.
- There is no `private_dns_zone_id` input. The private endpoint's `private_dns_zone_group` is excluded from lifecycle management (`ignore_changes`), so DNS registration for `privatelink.servicebus.windows.net` must be linked outside this module.
- Queue objects only support three optional attributes (`max_size_in_megabytes`, `default_message_ttl`, `lock_duration`) - no dead-lettering, duplicate detection, session support, or partitioning options. Extend the module yourself if you need those.
