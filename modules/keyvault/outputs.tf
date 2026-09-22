output "keyvault" {
  value       = azurerm_key_vault.keyvault
  description = "Complete Key Vault object"
}

output "keyvault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.keyvault.id
}

output "keyvault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.keyvault.name
}

output "keyvault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.keyvault.vault_uri
}

output "keyvault_tenant_id" {
  description = "The tenant ID associated with the Key Vault"
  value       = azurerm_key_vault.keyvault.tenant_id
}

output "private_endpoint_id" {
  description = "The ID of the private endpoint"
  value       = azurerm_private_endpoint.keyvault.id
}

output "private_endpoint_ip_address" {
  description = "The private IP address of the private endpoint"
  value       = azurerm_private_endpoint.keyvault.private_service_connection[0].private_ip_address
}

output "keyvault_subnet_id" {
  description = "The ID of the Key Vault subnet"
  value       = var.subnet_id
}

output "private_dns_zone_id" {
  description = "The ID of the private DNS zone"
  value       = data.azurerm_private_dns_zone.keyvault.id
}

output "secret_ids" {
  description = "Map of secret names to their IDs"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.id }
}

output "key_ids" {
  description = "Map of key names to their IDs"
  value       = { for k, v in azurerm_key_vault_key.keys : k => v.id }
}

output "certificate_ids" {
  description = "Map of certificate names to their IDs"
  value       = { for k, v in azurerm_key_vault_certificate.certificates : k => v.id }
}
