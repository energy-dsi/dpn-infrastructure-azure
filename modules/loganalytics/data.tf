# Data source to reference existing VNet in rg-dpn-dev-uks-01
data "azurerm_virtual_network" "existing_vnet" {
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group_name
}
