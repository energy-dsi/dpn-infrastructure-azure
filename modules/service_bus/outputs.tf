output "namespace_id" {
  description = "Resource ID of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.namespace.id
}

output "namespace_name" {
  description = "Name of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.namespace.name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.service_bus.name
}

output "queue_ids" {
  description = "Map of queue names to resource IDs"
  value       = { for k, v in azurerm_servicebus_queue.queues : k => v.id }
}
