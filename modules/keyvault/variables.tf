variable "location" {
  description = "The location/region where the key vault will be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which the key vault will be created"
  type        = string
}

variable "keyvault_name" {
  description = "The name of the key vault (3-24 characters, alphanumerics and hyphens only)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.keyvault_name))
    error_message = "Key Vault name must be 3-24 characters, containing only alphanumerics and hyphens."
  }
}

variable "keyvault_sku_name" {
  description = "The SKU name of the key vault. Possible values are standard and premium"
  type        = string
  validation {
    condition     = contains(["standard", "premium"], var.keyvault_sku_name)
    error_message = "SKU must be standard or premium."
  }
}

variable "soft_delete_retention_days" {
  description = "The number of days that items should be retained for once soft deleted (7-90 days)"
  type        = number
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

variable "purge_protection_enabled" {
  description = "Enable purge protection for the key vault"
  type        = bool
}

variable "enabled_for_disk_encryption" {
  description = "Enable Azure Disk Encryption to retrieve secrets from the vault"
  type        = bool
}

variable "enabled_for_deployment" {
  description = "Enable Azure Virtual Machines to retrieve certificates from the vault"
  type        = bool
}

variable "enabled_for_template_deployment" {
  description = "Enable Azure Resource Manager to retrieve secrets from the vault"
  type        = bool
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled for the key vault"
  type        = bool
}

variable "vnet_name" {
  description = "The name of the existing virtual network"
  type        = string
}

variable "vnet_resource_group_name" {
  description = "The name of the resource group in which the virtual network is located"
  type        = string
}

variable "vnet_subnet_name" {
  description = "The name of the subnet for the Key Vault private endpoint"
  type        = string
}

variable "network_acls_enabled" {
  description = "Enable network ACLs for the key vault"
  type        = bool
}

variable "network_acls_bypass" {
  description = "Specifies which traffic can bypass the network rules. Possible values are AzureServices and None"
  type        = string
  validation {
    condition     = contains(["AzureServices", "None"], var.network_acls_bypass)
    error_message = "Network ACLs bypass must be AzureServices or None."
  }
}

variable "network_acls_default_action" {
  description = "The default action when no rule matches. Possible values are Allow and Deny"
  type        = string
  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls_default_action)
    error_message = "Default action must be Allow or Deny."
  }
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access the key vault"
  type        = list(string)
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access the key vault"
  type        = list(string)
}

variable "private_dns_zone_subscription_id" {
  description = "Subscription ID hosting your private DNS zones"
  type        = string
}

variable "private_dns_zone_resource_group" {
  type = string
}

variable "key_vault_admin_object_ids" {
  description = "List of object IDs to grant Key Vault Administrator role"
  type        = list(string)
}

variable "key_vault_secrets_officer_object_ids" {
  description = "List of object IDs to grant Key Vault Secrets Officer role"
  type        = list(string)
}

variable "key_vault_secrets_user_object_ids" {
  description = "List of object IDs to grant Key Vault Secrets User role"
  type        = list(string)
}

variable "key_vault_crypto_officer_object_ids" {
  description = "List of object IDs to grant Key Vault Crypto Officer role"
  type        = list(string)
  default     = []
}

variable "key_vault_crypto_user_object_ids" {
  description = "List of object IDs to grant Key Vault Crypto User role"
  type        = list(string)
  default     = []
}

variable "initial_secrets" {
  description = "Map of initial secrets to create in the key vault. Set expiration_date (RFC3339, e.g. \"2027-01-01T00:00:00Z\") on every entry - secrets without one never expire."
  type = map(object({
    value           = string
    expiration_date = optional(string)
  }))
}

variable "initial_keys" {
  description = "Map of initial keys to create in the key vault. Set expiration_date (RFC3339, e.g. \"2027-01-01T00:00:00Z\") on every entry - keys without one never expire."
  type = map(object({
    key_type                      = string
    key_size                      = number
    key_opts                      = list(string)
    expiration_date               = optional(string)
    enable_rotation               = optional(bool, true)
    rotation_time_before_expiry   = optional(string, "P30D")
    rotation_expire_after         = optional(string, "P90D")
    rotation_notify_before_expiry = optional(string, "P29D")
  }))
}

variable "log_analytics_workspace_name" {
  description = "The name of the log analytics workspace"
  type        = string
}

variable "log_analytics_resource_group_name" {
  type = string
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for Key Vault"
  type        = bool
}

variable "rbac_authorization_enabled" {
  description = "Enable RBAC authorization for Key Vault"
  type        = bool
}

variable "subnet_id" {
  description = "Keyvault subnet ID passed directly from the root. When set, the azurerm_subnet data source is skipped (required on first deploy when the subnet does not yet exist in Azure)."
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID passed directly from the root. When set, the data source lookup is skipped (required on first deploy when the LAW does not yet exist)."
  type        = string
  default     = null
}

variable "bypass_data_sources" {
  description = "When true, skip subnet and log analytics data source reads and use subnet_id / log_analytics_workspace_id directly. Must be set to true on first deploy when these resources are created in the same apply."
  type        = bool
  default     = false
}

variable "keyvault_private_dns_zone_id" {
  description = "Full ARM resource ID of the privatelink.vaultcore.azure.net Private DNS zone (e.g. /subscriptions/.../privateDnsZones/privatelink.vaultcore.azure.net). When set, OpenTofu manages the private_dns_zone_group on the private endpoint so the A record lands in the correct zone."
  type        = string
  default     = null
}
