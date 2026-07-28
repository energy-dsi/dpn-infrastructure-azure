output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = { for k in keys(var.subnets) : k => "${data.azurerm_virtual_network.vnet.id}/subnets/${k}" }
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to their address prefixes"
  value       = { for k, v in var.subnets : k => [v.address_prefix] }
}

output "nsg_ids" {
  description = "Map of NSG names to their IDs"
  value       = { for k, v in azurerm_network_security_group.nsg : k => v.id }
}

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = data.azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = data.azurerm_virtual_network.vnet.name
}

output "vnet_address_space" {
  description = "The address space of the virtual network"
  value       = data.azurerm_virtual_network.vnet.address_space
}
