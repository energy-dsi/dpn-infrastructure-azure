variable "resource_group_name" {
  description = "Name of the dedicated resource group created for the Bastion host (and its public IP, for Basic/Standard/Premium SKU)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "bastion_host_name" {
  description = "Name of the Azure Bastion host"
  type        = string
}

variable "public_ip_name" {
  description = "Name of the Bastion host's public IP. Required for Basic/Standard/Premium SKU; not used for Developer SKU (no public IP is created)."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "ID of the AzureBastionSubnet (must be named exactly 'AzureBastionSubnet', minimum /26). Required for Basic/Standard/Premium SKU; not used for Developer SKU."
  type        = string
  default     = null
}

variable "virtual_network_id" {
  description = "ID of the VNet to attach a Developer SKU Bastion host to. Required (and only valid) when sku = \"Developer\"."
  type        = string
  default     = null
}

variable "sku" {
  description = "Azure Bastion SKU"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Developer", "Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be one of: Developer, Basic, Standard, Premium."
  }
}

variable "scale_units" {
  description = "Number of scale units (Standard/Premium only, 2-50)"
  type        = number
  default     = 2
}

variable "copy_paste_enabled" {
  description = "Enable copy/paste in Bastion sessions"
  type        = bool
  default     = true
}

variable "file_copy_enabled" {
  description = "Enable file copy in Bastion sessions (Standard/Premium only)"
  type        = bool
  default     = true
}

variable "tunneling_enabled" {
  description = "Enable native client support (az network bastion tunnel/rdp/ssh) (Standard/Premium only)"
  type        = bool
  default     = true
}

variable "ip_connect_enabled" {
  description = "Enable IP-based connection (Premium only)"
  type        = bool
  default     = false
}

variable "shareable_link_enabled" {
  description = "Enable shareable link (Standard/Premium only)"
  type        = bool
  default     = false
}

variable "kerberos_enabled" {
  description = "Enable Kerberos authentication"
  type        = bool
  default     = false
}

variable "zones" {
  description = "Availability zones for the Bastion host and its public IP"
  type        = list(string)
  default     = []
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings streaming Bastion audit logs to Log Analytics"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic settings"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
