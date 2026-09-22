output "bastion_id" {
  description = "ID of the Azure Bastion host"
  value       = azurerm_bastion_host.bastion.id
}

output "bastion_name" {
  description = "Name of the Azure Bastion host"
  value       = azurerm_bastion_host.bastion.name
}

output "bastion_public_ip" {
  description = "Public IP address of the Azure Bastion host (null for Developer SKU, which has no public IP)"
  value       = try(azurerm_public_ip.bastion[0].ip_address, null)
}

output "resource_group_name" {
  description = "Name of the resource group created for the Bastion host"
  value       = azurerm_resource_group.bastion.name
}
