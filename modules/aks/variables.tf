# ==============================================================================
# AKS Module Variables
# ==============================================================================

# ------------------------------------------------------------------------------
# Required Variables
# ------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group where AKS will be created"
  type        = string
}

variable "aks_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "vnet_subnet_name" {
  description = "Name of the subnet where AKS nodes will be deployed"
  type        = string
}

variable "vnet_resource_group_name" {
  description = "Name of the resource group containing the VNet"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace for monitoring"
  type        = string
}

variable "log_analytics_resource_group_name" {
  description = "Name of the resource group containing the Log Analytics workspace"
  type        = string
}

variable "container_registry_id" {
  description = "Resource ID of the Azure Container Registry"
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault for secrets management"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

# ------------------------------------------------------------------------------
# Optional Variables with Defaults
# ------------------------------------------------------------------------------

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string

}

variable "node_resource_group" {
  description = "Name of the resource group for AKS node infrastructure (VMs, disks, NICs, etc.)"
  type        = string
}

variable "private_cluster_enabled" {
  description = "Enable private cluster (API server accessible only via private endpoint)"
  type        = bool
  default     = true
}

variable "private_dns_zone_id" {
  description = "Resource ID of the private DNS zone. Required when private_cluster_enabled is true"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
}

variable "sku_tier" {
  description = "SKU tier for the AKS cluster. Options: Free, Standard, Premium"
  type        = string
}

variable "automatic_upgrade_channel" {
  description = "Upgrade channel for Kubernetes. Options: patch, rapid, node-image, stable"
  type        = string
}

variable "node_os_upgrade_channel" {
  description = "Upgrade channel for node OS. Options: NodeImage, None, SecurityPatch, Unmanaged"
  type        = string
}

variable "vm_size" {
  description = "VM size for default node pool"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the default node pool (used when autoscaling is disabled)"
  type        = number
}

variable "enable_auto_scaling" {
  description = "Enable autoscaling for the default node pool"
  type        = bool
  default     = false
}

variable "min_count" {
  description = "Minimum number of nodes when autoscaling is enabled"
  type        = number
  default     = null
}

variable "max_count" {
  description = "Maximum number of nodes when autoscaling is enabled"
  type        = number
  default     = null
}

variable "aks_admin_group" {
  description = "Object IDs of Azure AD groups with AKS admin access"
  type        = list(string)
}

variable "service_cidr" {
  description = "CIDR block for Kubernetes services"
  type        = string
}

variable "dns_service_ip" {
  description = "IP address for Kubernetes DNS service (must be within service_cidr)"
  type        = string
}

# ------------------------------------------------------------------------------
# Workload Node Pool
# ------------------------------------------------------------------------------

variable "enable_workload_node_pool" {
  description = "Enable additional workload node pool for application workloads"
  type        = bool
}

variable "workload_node_pool_vm_size" {
  description = "VM size for workload node pool"
  type        = string
}

variable "workload_node_pool_count" {
  description = "Number of nodes in the workload node pool"
  type        = number
}

variable "workload_node_pool_taints" {
  description = "Taints to apply to workload node pool nodes"
  type        = list(string)
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for AKS cluster"
  type        = bool
}

variable "service_mesh_mode" {
  description = "Service mesh mode (Istio or Disabled)"
  type        = string
}

variable "service_mesh_revisions" {
  description = "List of Istio revisions to enable"
  type        = list(string)
}

variable "identity_type" {
  description = "Type of managed identity (SystemAssigned or UserAssigned)"
  type        = string
}

variable "http_application_routing_enabled" {
  description = "Enable HTTP application routing (deprecated)"
  type        = bool
}

variable "node_pool_zones" {
  description = "Availability zones for the default node pool"
  type        = list(number)
}

variable "max_surge" {
  description = "Maximum number or percentage of nodes which will be added during an upgrade"
  type        = string
}

variable "drain_timeout_in_minutes" {
  description = "The amount of time in minutes to wait on eviction of pods"
  type        = number
}

variable "node_soak_duration_in_minutes" {
  description = "The amount of time in minutes to wait after draining a node"
  type        = number
}

variable "network_plugin_mode" {
  description = "Network plugin mode (overlay or blank for default)"
  type        = string
}

variable "secret_rotation_enabled" {
  description = "Enable automatic rotation of Key Vault secrets"
  type        = bool
}

variable "secret_rotation_interval" {
  description = "Rotation poll interval for Key Vault secrets"
  type        = string
}

variable "workload_node_pool_zones" {
  description = "Availability zones for the workload node pool"
  type        = list(number)
}

variable "azure_policy_enabled" {
  description = "Enable Azure Policy for AKS cluster"
  type        = bool
  default     = true
}

variable "local_account_disabled" {
  description = "Disable local accounts (enforce Azure AD only)"
  type        = bool
  default     = true
}

variable "oidc_issuer_enabled" {
  description = "Enable OIDC issuer for workload identity"
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Enable workload identity"
  type        = bool
  default     = true
}

variable "host_encryption_enabled" {
  description = "Enable host-based encryption for AKS nodes"
  type        = bool
  default     = true
}

variable "network_plugin" {
  description = "Network plugin for AKS (azure or kubenet)"
  type        = string
}

variable "network_policy" {
  description = "Network policy for AKS (azure, calico, or cilium)"
  type        = string
}

variable "load_balancer_sku" {
  description = "SKU for load balancer (basic or standard)"
  type        = string
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = true
}

variable "connectivity_subscription_id" {
  description = "Subscription ID where central Private DNS zones are located"
  type        = string
}

variable "private_dns_zone_resource_group" {
  description = "Resource group name for central Private DNS zones"
  type        = string
}

# ------------------------------------------------------------------------------
# Hardcoded Values Now Parameterized
# ------------------------------------------------------------------------------

variable "default_node_pool_name" {
  description = "Name of the default node pool"
  type        = string
}

variable "workload_node_pool_name" {
  description = "Name of the workload node pool"
  type        = string
}

variable "workload_node_pool_host_encryption_enabled" {
  description = "Enable host-based encryption for workload node pool nodes"
  type        = bool
  default     = true
}

variable "workload_node_pool_label_key" {
  description = "Label key for workload node pool"
  type        = string
}

variable "workload_node_pool_label_value" {
  description = "Label value for workload node pool"
  type        = string
}

variable "acr_pull_role_name" {
  description = "Role definition name for ACR pull access"
  type        = string
}

variable "user_assigned_identity_type" {
  description = "Identity type for User Assigned Identity (required for custom private DNS zone)"
  type        = string
}

variable "diagnostic_all_metrics_category" {
  description = "Category name for all metrics in diagnostic settings"
  type        = string
}

variable "diagnostic_all_logs_category_group" {
  description = "Category group name for all logs in diagnostic settings"
  type        = string
}

variable "external_acr_pull_principal_ids" {
  description = "List of external principal IDs (e.g. managed identities from other subscriptions) to grant AcrPull on this ACR"
  type        = list(string)
  default     = []
}

variable "subnet_id" {
  description = "Subnet ID for AKS node pools and network contributor role assignment"
  type        = string
}

variable "vnet_id" {
  description = "VNet ID for AKS network contributor role assignment"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for OMS agent and diagnostic settings"
  type        = string
}
