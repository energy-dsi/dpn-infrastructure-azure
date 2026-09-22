# Storage Account Module

## Purpose in this architecture

This module is reused three times in the root config, once per storage account: developer storage (`dev_storage`), the file-scanning pattern's landing zone (`file_scanning_service_storage`), and observability log export (`observability_logging_storage`). Each deployment gets its own private endpoint, and can optionally get an Azure Files share too - none of the three enable one by default in the example `dpn_infrastructure.tfvars`.

This module creates an Azure Storage Account for developer use with:
- Private endpoint connectivity
- Optional Azure Files share support
- Blob Data Contributor role for dev team
- Diagnostic settings integration
- Network security controls

## Features
- Secure private network access
- Optional private Azure Files endpoint
- Automatic role assignment for developers
- Soft delete protection
- Versioning enabled
- TLS 1.2 minimum

## Usage
```hcl
module "dev_storage" {
  source = "./modules/storage"
  
  storage_account_name  = "stdevappname"
  resource_group_name   = "rg-storage-dev"
  dev_team_spn_object_id = "..."
  subnet_id             = module.networking.subnet_ids["storage"]
  # ... other required variables
}
```

## Outputs
- storage_account_id
- storage_account_name
- primary_blob_endpoint
- resource_group_name
- file_share_name
- file_private_endpoint_id

## Customer-Managed Key (CMK) Encryption

Set `encryption_enabled = true` plus `key_vault_key_id` and `key_vault_id` to encrypt this storage account with your own Key Vault key instead of a Microsoft-managed one. The module creates its own user-assigned identity and grants it `Key Vault Crypto Service Encryption User` on `key_vault_id` so it can wrap/unwrap the key. This is independent of `infrastructure_encryption_enabled` (the hardcoded double-layer Microsoft-managed encryption above) - both can be on at once.
