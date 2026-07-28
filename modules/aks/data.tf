data "azurerm_subnet" "aks_subnet" {
  count                = var.bypass_data_sources ? 0 : 1
  name                 = var.vnet_subnet_name
  resource_group_name  = var.vnet_resource_group_name
  virtual_network_name = var.vnet_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group_name
}

data "azurerm_log_analytics_workspace" "log_analytics" {
  count               = var.bypass_data_sources ? 0 : 1
  name                = var.log_analytics_workspace_name
  resource_group_name = var.log_analytics_resource_group_name
}

data "azurerm_subscription" "current" {}
