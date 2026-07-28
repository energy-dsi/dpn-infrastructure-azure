variable "workspace_name" {
  description = "Name of the Log Analytics workspace (used for resource naming)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group in which to create AMPLS resources (same RG as the Log Analytics workspace)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace to link to AMPLS"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the AMPLS private endpoint"
  type        = string
}

variable "ods_private_dns_zone_id" {
  description = "Full ARM resource ID of the privatelink.ods.opinsights.azure.com Private DNS zone"
  type        = string
  default     = null
}

variable "oms_private_dns_zone_id" {
  description = "Full ARM resource ID of the privatelink.oms.opinsights.azure.com Private DNS zone"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
