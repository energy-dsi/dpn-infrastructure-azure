# Event Grid Custom Topic Module

## Purpose in this architecture

This module creates a private Azure Event Grid custom topic. In this reference architecture it exists as the ingestion point for **Microsoft Defender for Storage malware-scan-result events**, as part of a file-scanning pattern: a file lands in a storage account, Defender for Storage scans it, and the scan verdict is published as an event. This topic receives that event so a downstream consumer (typically via a Service Bus subscription - see `modules/service_bus`) can act on it - e.g. only allow clean files to proceed to their destination.

If your workload has a different reason to need a private Event Grid topic, this module works standalone too - just don't assume the `public_network_access_enabled` default is safe to change without reading the note below first.

## The constraint that shapes this module: public network access

**Microsoft Defender for Storage cannot deliver its malware-scan-result events to an Event Grid topic that only accepts traffic on a private endpoint.** This is a confirmed Microsoft/Azure platform limitation, not a misconfiguration in this module or something fixable with different Terraform settings. Because of this:

- `public_network_access_enabled` defaults to `false` in this module, but the example `dpn_infrastructure.tfvars` overrides it to `true`, because this deployment's topic does receive Defender for Storage events.
- A private endpoint is *also* always deployed regardless of this setting (so Data Receiver/Sender/Contributor traffic from inside your VNet stays private).
- If this topic is wired to receive Defender for Storage events, don't set `event_grid_public_network_access_enabled` back to `false` - scan results will silently stop arriving with no obvious error on the Defender for Storage side.
- If your deployment doesn't receive Defender for Storage events (some other use case), `false` (the module default) is safe.

This is why `CKV_AZURE_193` ("Ensure public network access is disabled for Azure Event Grid Topic") is listed as an accepted, documented exception in `.checkov.yaml` rather than fixed - fixing it would break the feature this module exists for.

## Features

### Networking & Security
- **Own Resource Group** - the module creates `azurerm_resource_group.event_grid` rather than deploying into an existing one
- **Private Endpoint** - single subresource `topic`, named `pe-<topic_name>` - always created regardless of `public_network_access_enabled`
- **Local auth toggle** - `local_auth_enabled` (default `false`) to disable SAS-key authentication and enforce Azure AD only
- **Public network access** - controlled by `public_network_access_enabled` (module default `false` - see the constraint above)
- **System-assigned managed identity** on the topic itself (`CKV_AZURE_191`), additive to the RBAC role assignments below

### RBAC
- **EventGrid Data Receiver** - granted per-principal via `data_receiver_principal_ids`
- **EventGrid Data Sender** - granted per-principal via `data_sender_principal_ids`
- **EventGrid Contributor** - granted per-principal via `contributor_principal_ids`

### Monitoring
- **Diagnostic Setting** - `allLogs` category group plus `AllMetrics`, sent to Log Analytics, toggled by `enable_diagnostic_settings` (default `true`)

```
┌────────────────────────────────────────────────────────────────┐
│  Resource Group (module-managed)                                │
│                                                                    │
│   Event Grid Custom Topic (public network access: per var)      │
│     ├─ Private Endpoint (pe-<topic_name>, subresource: topic)   │
│     ├─ RBAC: Data Receiver / Data Sender / Contributor          │
│     └─ Diagnostic Setting → Log Analytics (allLogs, AllMetrics) │
└────────────────────────────────────────────────────────────────┘
        ▲                                    │
        │ Defender for Storage scan events   │ (event subscription -
        │ (needs public network access)      │  not included, add if needed)
        │                                     ▼
  Storage account being scanned        Service Bus (modules/service_bus)
```

## Usage

```hcl
module "event_grid" {
  source = "../modules/event_grid"

  topic_name                    = var.event_grid_topic_name
  resource_group_name           = var.event_grid_resource_group_name
  location                      = var.location
  local_auth_enabled            = var.event_grid_local_auth_enabled
  public_network_access_enabled = var.event_grid_public_network_access_enabled
  subnet_id                     = module.networking.subnet_ids[var.event_grid_subnet_name]
  data_receiver_principal_ids   = var.event_grid_data_receiver_principal_ids
  data_sender_principal_ids     = var.event_grid_data_sender_principal_ids
  contributor_principal_ids     = var.event_grid_contributor_principal_ids
  enable_diagnostic_settings    = var.event_grid_enable_diagnostic_settings
  log_analytics_workspace_id    = module.loganalytics.log_analytics_workspace_id
  tags                          = var.tags

  depends_on = [module.networking, module.loganalytics]
}
```

## Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `topic_name` | Name of the Event Grid custom topic | `string` | - | yes |
| `resource_group_name` | Name of the resource group (created by this module) | `string` | - | yes |
| `location` | Azure region | `string` | - | yes |
| `subnet_id` | Subnet ID for the private endpoint | `string` | - | yes |
| `data_receiver_principal_ids` | Principal IDs granted `EventGrid Data Receiver` | `list(string)` | `[]` | no |
| `data_sender_principal_ids` | Principal IDs granted `EventGrid Data Sender` | `list(string)` | `[]` | no |
| `contributor_principal_ids` | Principal IDs granted `EventGrid Contributor` | `list(string)` | `[]` | no |
| `local_auth_enabled` | Enable SAS-key local authentication; disable to enforce Azure AD only | `bool` | `false` | no |
| `public_network_access_enabled` | Enable public network access. Keep `true` if this topic receives Defender for Storage events (see constraint above) | `bool` | `false` | no |
| `enable_diagnostic_settings` | Enable diagnostic settings | `bool` | `true` | no |
| `log_analytics_workspace_id` | Log Analytics workspace ID for diagnostic settings | `string` | `null` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

- `topic_id` - Resource ID of the Event Grid custom topic
- `topic_endpoint` - Endpoint URL of the Event Grid custom topic

## Customer-Managed Key (CMK) Encryption

Not supported. Event Grid custom topics encrypt data at rest with a Microsoft-managed key only - the `azurerm_eventgrid_topic` resource has no customer-managed key option, and Azure does not currently offer one for this resource type.

## Notes

- This module creates its own resource group - do not point `resource_group_name` at a resource group managed elsewhere, as this module owns its lifecycle.
- There is no `private_dns_zone_id` input. The private endpoint's `private_dns_zone_group` is excluded from lifecycle management (`ignore_changes`), so DNS registration for `privatelink.eventgrid.azure.net` must be linked outside this module.
- This module does not enable Microsoft Defender for Storage - that's a setting on the storage account/subscription in Defender for Cloud.
- This module does not create the event subscription that connects a storage account's Defender for Storage events to this topic, nor the subscription forwarding events onward to Service Bus. Those are `azurerm_eventgrid_event_subscription` resources this codebase does not currently declare - add them if you need this wiring end-to-end.
