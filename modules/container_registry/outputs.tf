output "acr_container_registry" {
  value       = azurerm_container_registry.acr
  description = "Complete Azure Container Registry object"
}

output "acr_id" {
  description = "The ID of the Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "acr_name" {
  description = "The name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "The login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "The admin username for the Azure Container Registry (if admin enabled)"
  value       = var.admin_enabled ? azurerm_container_registry.acr.admin_username : null
}

output "acr_admin_password" {
  description = "The admin password for the Azure Container Registry (if admin enabled)"
  value       = var.admin_enabled ? azurerm_container_registry.acr.admin_password : null
  sensitive   = true
}

output "private_endpoint_id" {
  description = "The ID of the private endpoint"
  value       = azurerm_private_endpoint.acr.id
}

output "private_endpoint_ip_address" {
  description = "The private IP address of the private endpoint"
  value       = azurerm_private_endpoint.acr.private_service_connection[0].private_ip_address
}

output "acr_subnet_id" {
  description = "The ID of the ACR subnet"
  value       = var.subnet_id
}

output "private_dns_zone_id" {
  description = "The ID of the private DNS zone"
  value       = data.azurerm_private_dns_zone.acr.id
}

output "user_assigned_identity_id" {
  description = "The ID of the user-assigned managed identity (if encryption enabled)"
  value       = var.encryption_enabled ? azurerm_user_assigned_identity.acr[0].id : null
}

output "user_assigned_identity_principal_id" {
  description = "The principal ID of the user-assigned managed identity (if encryption enabled)"
  value       = var.encryption_enabled ? azurerm_user_assigned_identity.acr[0].principal_id : null
}
