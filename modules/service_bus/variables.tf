variable "namespace_name" {
  description = "Name of the Service Bus namespace"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sku" {
  description = "SKU for the Service Bus namespace (Basic, Standard, Premium). Premium required for private endpoints."
  type        = string
  default     = "Premium"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be Basic, Standard, or Premium."
  }
}

variable "capacity" {
  description = "Messaging units for Premium tier (1, 2, 4, 8, or 16)"
  type        = number
  default     = 1
}

variable "premium_messaging_partitions" {
  description = "Number of messaging partitions for Premium tier (1, 2, or 4)"
  type        = number
  default     = 1
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "local_auth_enabled" {
  description = "Enable local authentication (SAS tokens). Disable to enforce Azure AD only."
  type        = bool
  default     = false
}

variable "trusted_services_allowed" {
  description = "Allow trusted Microsoft services to bypass network rules"
  type        = bool
  default     = true
}

variable "minimum_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
}

variable "subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Full ARM resource ID of the privatelink.servicebus.windows.net Private DNS zone"
  type        = string
  default     = null
}

variable "queues" {
  description = "Map of Service Bus queues to create"
  type = map(object({
    max_size_in_megabytes                = optional(number, 1024)
    default_message_ttl                  = optional(string, "P14D")
    lock_duration                        = optional(string, "PT1M")
    dead_lettering_on_message_expiration = optional(bool, false)
    max_delivery_count                   = optional(number, 10)
    requires_duplicate_detection         = optional(bool, false)
    requires_session                     = optional(bool, false)
    partitioning_enabled                 = optional(bool, false)
  }))
  default = {}
}

variable "data_receiver_principal_ids" {
  description = "List of principal IDs to grant Azure Service Bus Data Receiver role"
  type        = list(string)
  default     = []
}

variable "data_sender_principal_ids" {
  description = "List of principal IDs to grant Azure Service Bus Data Sender role"
  type        = list(string)
  default     = []
}

variable "data_owner_principal_ids" {
  description = "List of principal IDs to grant Azure Service Bus Data Owner role"
  type        = list(string)
  default     = []
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic settings"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
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
  description = "Resource ID of the Key Vault holding key_vault_key_id. Required when encryption_enabled is true — the module grants the namespace encryption identity Key Vault Crypto Service Encryption User on this vault so it can wrap/unwrap the CMK."
  type        = string
  default     = null
}
