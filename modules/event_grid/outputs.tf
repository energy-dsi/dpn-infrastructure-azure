output "topic_id" {
  description = "Event Grid topic resource ID"
  value       = azurerm_eventgrid_topic.event_grid.id
}

output "topic_endpoint" {
  description = "Event Grid topic endpoint"
  value       = azurerm_eventgrid_topic.event_grid.endpoint
}
