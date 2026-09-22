variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "sas_expiration_period" {
  description = "CKV2_AZURE_41: max lifetime for account-level SAS tokens, format DD.HH:MM:SS"
  type        = string
  default     = "07.00:00:00"
}

variable "account_kind" {
  description = "Storage account kind"
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  description = "Storage account access tier"
  type        = string
  default     = "Hot"
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "allow_nested_items_to_be_public" {
  description = "Allow nested items to be public"
  type        = bool
  default     = false
}

variable "min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"
}

variable "enable_https_traffic_only" {
  description = "Enable HTTPS traffic only"
  type        = bool
  default     = true
}

variable "shared_access_key_enabled" {
  description = "Enable shared access key"
  type        = bool
  default     = true
}

variable "is_hns_enabled" {
  description = "Enable hierarchical namespace"
  type        = bool
  default     = false
}

variable "large_file_share_enabled" {
  description = "Enable large file share"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "blob_retention_days" {
  description = "Blob soft delete retention days"
  type        = number
  default     = 7
}

variable "container_retention_days" {
  description = "Container soft delete retention days"
  type        = number
  default     = 7
}

variable "network_rules_default_action" {
  description = "Default action for network rules"
  type        = string
  default     = "Deny"
}

variable "network_rules_bypass" {
  description = "Bypass for network rules"
  type        = list(string)
  default     = ["AzureServices"]
}

variable "network_rules_ip_rules" {
  description = "IP rules for network access"
  type        = list(string)
  default     = []
}

variable "network_rules_subnet_ids" {
  description = "Subnet IDs for network access"
  type        = list(string)
  default     = []
}

variable "dev_team_spn_object_id" {
  description = "Object ID of dev team SPN for Storage Blob Data Contributor role"
  type        = string
}

variable "additional_blob_contributor_principal_ids" {
  description = "Additional principal IDs to grant Storage Blob Data Contributor role"
  type        = list(string)
  default     = []
}

variable "create_blob_endpoint" {
  description = "Create private endpoint for blob"
  type        = bool
  default     = true
}

variable "file_share_name" {
  description = "Name of the Azure Files share to create"
  type        = string
  default     = ""
}

variable "file_share_quota_gb" {
  description = "Quota for the Azure Files share in GB"
  type        = number
  default     = 1
}

variable "create_file_endpoint" {
  description = "Create private endpoint for Azure Files"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
}

variable "blob_private_dns_zone_id" {
  description = "Private DNS zone ID for blob storage (deprecated - will use data source)"
  type        = string
  default     = ""
}

variable "private_dns_zone_resource_group" {
  description = "Resource group name for private DNS zones"
  type        = string
}

variable "connectivity_subscription_id" {
  description = "Subscription ID for connectivity resources"
  type        = string
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
}

variable "encryption_enabled" {
  description = "Enable customer-managed key (CMK) encryption for this storage account"
  type        = bool
  default     = false
}

variable "key_vault_key_id" {
  description = "Key Vault key ID for customer-managed encryption. Required when encryption_enabled is true."
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault holding key_vault_key_id. Required when encryption_enabled is true - the module grants the storage encryption identity Key Vault Crypto Service Encryption User on this vault so it can wrap/unwrap the CMK."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
