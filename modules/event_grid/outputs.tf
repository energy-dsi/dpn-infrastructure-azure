output "topic_id" {
  description = "Resource ID of the Event Grid custom topic"
  value       = azurerm_eventgrid_topic.topic.id
}

output "topic_endpoint" {
  description = "Endpoint URL of the Event Grid custom topic"
  value       = azurerm_eventgrid_topic.topic.endpoint
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.event_grid.name
}
