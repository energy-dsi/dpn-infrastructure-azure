variable "acr_name" {
  type        = string
  description = "The name of the Azure Container Registry"
}

variable "sku" {
  type        = string
  description = "The SKU of the Azure Container Registry. Possible values are Basic, Standard, and Premium"
  # Default reflects every current environment's tfvars (all Premium). Lets Checkov's
  # static analysis resolve the Premium-gated attributes below (quarantine_policy_enabled,
  # retention_policy_in_days, data_endpoint_enabled, zone_redundancy_enabled) when scanning
  # this module in isolation without a var-file; tfvars still take precedence per-environment.
  default = "Premium"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be Basic, Standard, or Premium."
  }
}

variable "anonymous_pull_enabled" {
  type        = bool
  description = "Allow anonymous pull access to the Azure Container Registry"
}

variable "admin_enabled" {
  type        = bool
  description = "Enable admin account for the Azure Container Registry"
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether public network access is enabled for the container registry"
}

variable "zone_redundancy_enabled" {
  type        = bool
  description = "Enable zone redundancy for the container registry (Premium SKU only)"
}

variable "location" {
  type        = string
  description = "The location of the Azure Container Registry"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group for the Azure Container Registry"
}

variable "vnet_name" {
  type        = string
  description = "Name of the existing Virtual Network"
}

variable "vnet_resource_group_name" {
  type        = string
  description = "Resource group name of the existing Virtual Network"
}

variable "network_rules_enabled" {
  type        = bool
  description = "Enable network rules for the container registry"
}

variable "network_rule_default_action" {
  type        = string
  description = "Default action for network rules. Possible values are Allow or Deny"
  validation {
    condition     = contains(["Allow", "Deny"], var.network_rule_default_action)
    error_message = "Default action must be Allow or Deny."
  }
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "List of IP ranges allowed to access the container registry"
}

variable "retention_policy_enabled" {
  type        = bool
  description = "Enable retention policy for untagged manifests (Premium SKU only)"
}

variable "retention_policy_days" {
  type        = number
  description = "Number of days to retain untagged manifests"
  validation {
    condition     = var.retention_policy_days >= 0 && var.retention_policy_days <= 365
    error_message = "Retention policy days must be between 0 and 365."
  }
}

variable "trust_policy_enabled" {
  type        = bool
  description = "Enable trust policy (Docker Content Trust) for the container registry (Premium SKU only)"
}

variable "encryption_enabled" {
  type        = bool
  description = "Enable customer-managed key encryption (Premium SKU only)"
}

variable "key_vault_key_id" {
  type        = string
  description = "Key Vault key ID for customer-managed encryption"
}

variable "georeplications" {
  type = map(object({
    location                = string
    zone_redundancy_enabled = bool
  }))
  description = "Map of geo-replication configurations (Premium SKU only)"
}

variable "create_scope_maps" {
  type        = bool
  description = "Create default scope maps for pull and push access"
}

variable "webhooks" {
  type = map(object({
    service_uri    = string
    status         = string
    actions        = list(string)
    custom_headers = map(string)
  }))
  description = "Map of webhooks to create"
}

variable "connectivity_subscription_id" {
  description = "Subscription ID for the connectivity platform (Private DNS zones)"
  type        = string
}
variable "private_dns_zone_resource_group" {
  description = "Resource group name where private DNS zones are located in connectivity subscription"
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the Azure Container Registry"
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "The name of the Log Analytics workspace"
}

variable "log_analytics_resource_group_name" {
  type        = string
  description = "The name of the resource group for the Log Analytics workspace"
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for Container Registry"
  type        = bool
}

variable "subnet_id" {
  description = "Subnet ID for Container Registry private endpoint"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic settings"
  type        = string
}
