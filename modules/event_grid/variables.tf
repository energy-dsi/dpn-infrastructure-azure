variable "topic_name" {
  description = "Name of the Event Grid custom topic"
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

variable "public_network_access_enabled" {
  description = "Enable public network access. Microsoft Defender for Storage cannot deliver malware-scan-result events to an Event Grid topic that is restricted to a private endpoint only (confirmed Microsoft/platform limitation) - if this topic receives Defender for Storage events, this must stay true even though a private endpoint is also deployed."
  type        = bool
  default     = true
}

variable "local_auth_enabled" {
  description = "Enable local authentication (SAS keys). Disable to enforce Azure AD only"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Full ARM resource ID of the privatelink.eventgrid.azure.net Private DNS zone"
  type        = string
  default     = null
}

variable "data_receiver_principal_ids" {
  description = "List of principal IDs to grant EventGrid Data Receiver role"
  type        = list(string)
  default     = []
}

variable "data_sender_principal_ids" {
  description = "List of principal IDs to grant EventGrid Data Sender role"
  type        = list(string)
  default     = []
}

variable "contributor_principal_ids" {
  description = "List of principal IDs to grant EventGrid Contributor role"
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
