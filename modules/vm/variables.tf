# ========================================
# Resource Group Variables
# ========================================

variable "resource_group_name" {
  description = "Name of the resource group for the VM"
  type        = string
}

variable "location" {
  description = "Azure region for the VM"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ========================================
# VM Configuration Variables
# ========================================

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
}

variable "computer_name" {
  description = "Windows computer name (max 15 characters)"
  type        = string
}

variable "admin_username" {
  description = "Administrator username for the VM"
  type        = string
}

variable "admin_password" {
  description = "Administrator password for the VM"
  type        = string
  sensitive   = true
}

# ========================================
# Network Configuration Variables
# ========================================

variable "subnet_id" {
  description = "ID of the subnet to attach the VM to"
  type        = string
}

variable "private_ip_allocation" {
  description = "Private IP allocation method (Dynamic or Static)"
  type        = string
  default     = "Dynamic"
}

variable "private_ip_address" {
  description = "Static private IP address (if private_ip_allocation is Static)"
  type        = string
  default     = null
}

variable "create_nsg" {
  description = "Whether to create a network security group"
  type        = bool
  default     = false
}

# ========================================
# OS Disk Variables
# ========================================

variable "os_disk_caching" {
  description = "Caching type for the OS disk"
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  description = "Storage account type for the OS disk"
  type        = string
  default     = "Premium_LRS"
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB"
  type        = number
  default     = 127
}

# ========================================
# Image Variables
# ========================================

variable "image_publisher" {
  description = "Publisher of the VM image"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "image_offer" {
  description = "Offer of the VM image"
  type        = string
  default     = "WindowsServer"
}

variable "image_sku" {
  description = "SKU of the VM image"
  type        = string
  default     = "2022-datacenter-azure-edition"
}

variable "image_version" {
  description = "Version of the VM image"
  type        = string
  default     = "latest"
}

# ========================================
# Identity Variables
# ========================================

variable "identity_type" {
  description = "Type of managed identity (SystemAssigned, UserAssigned, or null for none)"
  type        = string
  default     = "SystemAssigned"
}

# ========================================
# Boot Diagnostics Variables
# ========================================

variable "enable_boot_diagnostics" {
  description = "Whether to enable boot diagnostics"
  type        = bool
  default     = true
}

variable "boot_diagnostics_storage_account_uri" {
  description = "Storage account URI for boot diagnostics (null for managed storage)"
  type        = string
  default     = null
}

# ========================================
# Security and Patching Variables
# ========================================

variable "bypass_platform_safety_checks_on_user_schedule_enabled" {
  description = "Whether to bypass platform safety checks on user schedule (required when patch_mode = AutomaticByPlatform)"
  type        = bool
  default     = true
}

variable "patch_mode" {
  description = "Patch mode for the VM (AutomaticByOS, AutomaticByPlatform, Manual)"
  type        = string
  default     = "AutomaticByPlatform"
}

variable "patch_assessment_mode" {
  description = "Patch assessment mode (AutomaticByPlatform or ImageDefault)"
  type        = string
  default     = "AutomaticByPlatform"
}

variable "enable_automatic_updates" {
  description = "Whether to enable automatic updates"
  type        = bool
  default     = true
}

variable "encryption_at_host_enabled" {
  description = "Whether to enable encryption at host"
  type        = bool
  default     = true
}

variable "secure_boot_enabled" {
  description = "Whether to enable secure boot (requires Gen2 VM)"
  type        = bool
  default     = true
}

variable "vtpm_enabled" {
  description = "Whether to enable vTPM (requires Gen2 VM)"
  type        = bool
  default     = true
}

variable "license_type" {
  description = "License type for the VM (None, Windows_Server, Windows_Client)"
  type        = string
  default     = "None"
}

variable "timezone" {
  description = "Timezone for the VM"
  type        = string
  default     = "GMT Standard Time"
}

variable "availability_zone" {
  description = "Availability zone for the VM (null for non-zonal deployment)"
  type        = string
  default     = null
}

# ========================================
# Diagnostic Settings Variables
# ========================================

variable "enable_diagnostic_settings" {
  description = "Whether to enable diagnostic settings"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for diagnostics"
  type        = string
  default     = null
}

# ========================================
# Key Vault Variables
# ========================================

variable "encryption_enabled" {
  description = "Enable customer-managed key (CMK) encryption for the OS disk via a disk encryption set"
  type        = bool
  default     = false
}

variable "key_vault_key_id" {
  description = "Key Vault key ID for OS disk customer-managed encryption. Required when encryption_enabled is true."
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "ID of the Key Vault to store VM password"
  type        = string
}

variable "vm_password_secret_expiration_duration" {
  description = "Duration for VM password secret expiry (e.g. 720h for 30 days)"
  type        = string
  default     = "17520h"

  validation {
    condition     = can(regex("^[0-9]+h$", var.vm_password_secret_expiration_duration))
    error_message = "vm_password_secret_expiration_duration must be in hours format, e.g. 720h."
  }
}
