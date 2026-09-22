variable "namespace_name" {
  description = "Name of the Service Bus namespace"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for Service Bus"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "sku" {
  description = "SKU for the Service Bus namespace (Basic, Standard, Premium). Premium required for private endpoints."
  type        = string
  default     = "Premium"
}

variable "subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
}

variable "queues" {
  description = "Map of queues to create in the Service Bus namespace"
  type = map(object({
    max_size_in_megabytes = optional(number, 1024)
    default_message_ttl   = optional(string, "P14D")
    lock_duration         = optional(string, "PT1M")
  }))
  default = {}
}

variable "data_receiver_principal_ids" {
  description = "Principal IDs to grant Azure Service Bus Data Receiver role"
  type        = list(string)
  default     = []
}

variable "data_sender_principal_ids" {
  description = "Principal IDs to grant Azure Service Bus Data Sender role"
  type        = list(string)
  default     = []
}

variable "data_owner_principal_ids" {
  description = "Principal IDs to grant Azure Service Bus Data Owner role"
  type        = list(string)
  default     = []
}

variable "public_network_access_enabled" {
  description = "Enable public network access for the Service Bus namespace"
  type        = bool
  default     = false
}

variable "minimum_tls_version" {
  description = "Minimum TLS version for the Service Bus namespace"
  type        = string
  default     = "1.2"
}

variable "capacity" {
  description = "Messaging units for Premium SKU (1, 2, 4, 8, or 16)"
  type        = number
  default     = 1
}

variable "premium_messaging_partitions" {
  description = "Number of premium messaging partitions (0, 1, or 2)"
  type        = number
  default     = 1
}

variable "local_auth_enabled" {
  description = "Enable local authentication (SAS keys) for the Service Bus namespace"
  type        = bool
  default     = false
}

variable "trusted_services_allowed" {
  description = "Allow trusted Microsoft services to bypass network rules and access the Service Bus namespace"
  type        = bool
  default     = false
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

variable "encryption_enabled" {
  description = "Enable customer-managed key (CMK) encryption. Requires sku = \"Premium\" (Azure platform requirement)."
  type        = bool
  default     = false
}

variable "key_vault_key_id" {
  description = "Key Vault key ID for customer-managed encryption. Required when encryption_enabled is true."
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault holding key_vault_key_id. Required when encryption_enabled is true - the module grants the namespace encryption identity Key Vault Crypto Service Encryption User on this vault so it can wrap/unwrap the CMK."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
