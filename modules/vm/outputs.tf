# ========================================
# VM Outputs
# ========================================

output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_windows_virtual_machine.vm.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_windows_virtual_machine.vm.name
}

output "private_ip_address" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.vm.private_ip_address
}

output "network_interface_id" {
  description = "ID of the network interface"
  value       = azurerm_network_interface.vm.id
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.vm.name
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity"
  value       = try(azurerm_windows_virtual_machine.vm.identity[0].principal_id, null)
}
