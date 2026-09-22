variable "topic_name" {
  description = "Name of the Event Grid topic"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for Event Grid"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
}

variable "data_receiver_principal_ids" {
  description = "Principal IDs to grant EventGrid Data Receiver role"
  type        = list(string)
  default     = []
}

variable "data_sender_principal_ids" {
  description = "Principal IDs to grant EventGrid Data Sender role"
  type        = list(string)
  default     = []
}

variable "contributor_principal_ids" {
  description = "Principal IDs to grant EventGrid Contributor role"
  type        = list(string)
  default     = []
}

variable "local_auth_enabled" {
  description = "Enable local authentication for the Event Grid topic"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access for the Event Grid topic"
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
