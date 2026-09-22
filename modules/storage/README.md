# Storage Account Module

## Purpose in this architecture

This is a generic, reusable Azure Storage Account module - it doesn't know or care what you use it for. The root configuration (`dpn-azure-infrastructure/main.tf`) invokes it **three times**, once per distinct role:

| Root module block | Role |
|--------------------|------|
| `dev_storage` | General-purpose storage for developer tooling - not tied to any specific application pattern. |
| `file_scanning_storage` | The "landing zone" storage account in the file-scanning pattern (see root `README.md`): files are uploaded here, Microsoft Defender for Storage scans them, and the scan-result event flows out via `modules/event_grid` and `modules/service_bus`. This module does **not** move files anywhere itself - a separate consumer application (outside this codebase) is responsible for reading the scan verdict and copying clean files to their real destination. |
| `observability_logging_storage` | A destination for diagnostic/log data export, separate from Log Analytics (e.g. long-term archival, or data a downstream tool reads directly from blob storage rather than querying Log Analytics). |

Each deployment gets its own resource group, private endpoint(s), and (optionally) its own customer-managed key - they are entirely independent storage accounts that happen to share this module's code.

## Features
- Private endpoint connectivity (blob, and optionally file share)
- Azure AD/RBAC-based access by default - `shared_access_key_enabled` defaults to `false`, since this module already grants access via Storage Blob Data Contributor/Reader role assignments rather than handing out account keys
- Queue logging enabled by default (`queue_logging_enabled`)
- Soft delete + versioning enabled by default
- TLS 1.2 minimum
- Optional customer-managed key (CMK) encryption

## Usage
```hcl
module "dev_storage" {
  source = "../modules/storage"

  storage_account_name   = var.dev_storage_account_name
  resource_group_name    = var.dev_storage_resource_group_name
  location                = var.location
  dev_team_spn_object_id  = var.dev_team_spn_object_id
  subnet_id               = module.networking.subnet_ids["snet-dpn-azure-dev-uks-azuredevstorage"]
  private_dns_zone_subscription_id = var.private_dns_zone_subscription_id
  private_dns_zone_resource_group  = var.private_dns_zone_resource_group
  blob_private_dns_zone_id         = "/subscriptions/${var.private_dns_zone_subscription_id}/resourceGroups/${var.private_dns_zone_resource_group}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
  log_analytics_workspace_id       = module.loganalytics.log_analytics_workspace_id
  tags                             = var.tags
}
```

## Key Variables

| Name | Description | Default |
|------|-------------|---------|
| `storage_account_name` | Globally-unique storage account name | - (required) |
| `replication_type` | LRS/ZRS/GRS/RAGRS/etc. | `LRS` |
| `public_network_access_enabled` | Enable public network access | `false` |
| `shared_access_key_enabled` | Enable storage account key (Shared Key) auth. Leave `false` unless a consumer specifically requires account-key access instead of Azure AD/RBAC | `false` |
| `queue_logging_enabled` | Enable read/write/delete logging for the Queue service | `true` |
| `create_blob_endpoint` | Create a private endpoint for the blob subresource | `true` |
| `create_file_share` / `create_file_endpoint` | Optionally create an Azure Files share and its own private endpoint | `false` |
| `encryption_enabled` | Enable customer-managed key (CMK) encryption | `false` |

See `variables.tf` for the complete list (network rules, retention days, SAS policy, role-assignment principal IDs, etc.).

## Outputs
- `storage_account_id`
- `storage_account_name`
- `primary_blob_endpoint`
- `resource_group_name`

## Customer-Managed Key (CMK) Encryption

Set `encryption_enabled = true` plus `key_vault_key_id` and `key_vault_id` to
encrypt this storage account with your own Key Vault key instead of a
Microsoft-managed key. The module creates its own user-assigned identity and
grants it `Key Vault Crypto Service Encryption User` on `key_vault_id`.
