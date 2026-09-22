data "azurerm_subscription" "current" {}

# REMOVED: This data source is no longer used - we use var.private_dns_zone_id directly
# to avoid cluster replacement issues when the data source returns different values
# data "azurerm_private_dns_zone" "aks" {
#   provider            = azurerm.connectivity
#   name                = "privatelink.${var.location_short}.azmk8s.io"
#   resource_group_name = var.private_dns_zone_resource_group
# }
