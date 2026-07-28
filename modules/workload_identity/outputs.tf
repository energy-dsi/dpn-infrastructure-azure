# ========================================
# Workload Identity Module Outputs
# ========================================

output "client_id" {
  description = "The client ID of the user-assigned managed identity (use in K8s ServiceAccount annotation)"
  value       = azurerm_user_assigned_identity.workload_identity.client_id
}

output "principal_id" {
  description = "The principal ID (object ID) of the managed identity"
  value       = azurerm_user_assigned_identity.workload_identity.principal_id
}

output "identity_id" {
  description = "The resource ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.workload_identity.id
}

output "identity_name" {
  description = "The name of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.workload_identity.name
}

output "federated_credential_id" {
  description = "The resource ID of the federated identity credential"
  value       = azurerm_federated_identity_credential.aks.id
}
