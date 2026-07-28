variable "vnet_name" {
  description = "The name of the existing virtual network"
  type        = string
}

variable "vnet_resource_group_name" {
  description = "The resource group containing the virtual network"
  type        = string
}

variable "location" {
  description = "The location/region where resources will be created"
  type        = string
}

variable "location_short" {
  description = "Short name for location (e.g., uks for UK South)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming (e.g., dpn)"
  type        = string
}

variable "environment" {
  description = "Environment name for resource naming (e.g., dev, test, prod)"
  type        = string
}

variable "instance_number" {
  description = "Instance number for resource naming (e.g., 01, 02)"
  type        = string
}

variable "tags" {
  description = "Tags to assign to resources"
  type        = map(string)
}

variable "subnets" {
  description = "Map of subnets to create in the virtual network"
  type = map(object({
    address_prefix                    = string
    default_outbound_access_enabled   = optional(bool, true)
    private_endpoint_network_policies = optional(string, "Disabled")
    create_nsg                        = optional(bool, false)
    nsg_name                          = optional(string)
    delegation = optional(object({
      name                       = string
      service_delegation_name    = string
      service_delegation_actions = list(string)
    }))
    nsg_rules = optional(map(object({
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), {})
  }))
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for NSGs"
  type        = bool
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace for diagnostics"
  type        = string
}

variable "log_analytics_resource_group_name" {
  description = "Resource group name for Log Analytics workspace"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace for diagnostics"
  type        = string
}
