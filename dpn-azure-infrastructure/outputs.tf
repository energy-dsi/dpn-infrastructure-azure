# ========================================
# Networking Outputs
# ========================================
output "vnet_id" {
  description = "Virtual network ID"
  value       = module.networking.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet IDs"
  value       = module.networking.subnet_ids
}

# ========================================
# Log Analytics Outputs
# ========================================
output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = module.loganalytics.log_analytics_workspace_id
}

# ========================================
# Key Vault Outputs
# ========================================
output "keyvault_id" {
  description = "Key Vault ID"
  value       = module.keyvault.keyvault_id
}

output "keyvault_uri" {
  description = "Key Vault URI"
  value       = module.keyvault.keyvault_uri
}

# ========================================
# Container Registry Outputs
# ========================================
output "acr_id" {
  description = "Container Registry ID"
  value       = module.container_registry.acr_id
}

output "acr_login_server" {
  description = "Container Registry login server"
  value       = module.container_registry.acr_login_server
}

# ========================================
# AKS Outputs
# ========================================
output "aks_cluster_id" {
  description = "AKS cluster ID"
  value       = module.aks.aks_id
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.aks_name
}

output "aks_principal_id" {
  description = "AKS cluster identity principal ID"
  value       = module.aks.aks_principal_id
}

output "aks_oidc_issuer_url" {
  description = "AKS OIDC issuer URL for workload identity"
  value       = module.aks.aks_oidc_issuer_url
}

# ========================================
# Developer Storage Account Outputs
# ========================================
output "dev_storage_account_id" {
  description = "Developer storage account ID"
  value       = module.dev_storage.storage_account_id
}

output "dev_storage_account_name" {
  description = "Developer storage account name"
  value       = module.dev_storage.storage_account_name
}

output "dev_storage_file_share_name" {
  description = "Developer Azure Files share name"
  value       = module.dev_storage.file_share_name
}

# Note: Developer storage module doesn't export private_endpoint_ip_address output
# output "dev_storage_private_endpoint_ip" {
#   description = "Developer storage account private endpoint IP address"
#   value       = module.dev_storage.private_endpoint_ip_address
# }
