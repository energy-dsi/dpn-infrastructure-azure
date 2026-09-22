output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.log_analytics.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.log_analytics.name
}

output "log_analytics_workspace_primary_shared_key" {
  description = "The primary shared key for the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.log_analytics.primary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_workspace_id" {
  description = "The Workspace ID (GUID) of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.log_analytics.workspace_id
}
