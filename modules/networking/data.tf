data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group_name
}

data "azurerm_log_analytics_workspace" "log_analytics" {
  count               = var.enable_diagnostic_settings ? 1 : 0
  name                = var.log_analytics_workspace_name
  resource_group_name = var.log_analytics_resource_group_name
}
