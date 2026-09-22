output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.storage.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.storage.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.storage.primary_blob_endpoint
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.storage.name
}

output "file_share_name" {
  description = "Name of the Azure Files share"
  value       = try(azurerm_storage_share.file_share[0].name, null)
}

output "file_private_endpoint_id" {
  description = "ID of the Azure Files private endpoint"
  value       = try(azurerm_private_endpoint.file[0].id, null)
}
