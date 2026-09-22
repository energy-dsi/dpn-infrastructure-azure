# Data source to reference Key Vault private DNS zone from connectivity subscription
data "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.private_dns_zone_resource_group
  provider            = azurerm.connectivity
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

