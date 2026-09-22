# Data source to reference ACR private DNS zone from connectivity subscription
data "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.private_dns_zone_resource_group
  provider            = azurerm.connectivity
}