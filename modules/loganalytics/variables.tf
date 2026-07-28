variable "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace"
  type        = string
}

variable "location" {
  description = "The location of the Log Analytics Workspace"
  type        = string
}

variable "log_analytics_resource_group_name" {
  description = "The name of the Resource Group where the Log Analytics Workspace will be created"
  type        = string
}

variable "vnet_name" {
  description = "The name of the existing Virtual Network"
  type        = string
}

variable "vnet_resource_group_name" {
  description = "The name of the resource group where the VNet is located"
  type        = string
}

variable "private_dns_zone_subscription_id" {
  description = "Subscription ID hosting your private DNS zones"
  type        = string
}

variable "private_dns_zone_resource_group" {
  description = "Resource group name where private DNS zones are located"
  type        = string
}

variable "sku" {
  description = "SKU for Log Analytics workspace"
  type        = string
}

variable "retention_in_days" {
  description = "Data retention in days (30-730)"
  type        = number
}

variable "identity_type" {
  description = "Type of managed identity for Log Analytics workspace"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to the Log Analytics Workspace"
  type        = map(string)
}

