terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

resource "azurerm_monitor_private_link_scope" "ampls" {
  name                  = "ampls-${var.workspace_name}"
  resource_group_name   = var.resource_group_name
  ingestion_access_mode = "PrivateOnly"
  query_access_mode     = "PrivateOnly"
  tags                  = var.tags
}

resource "azurerm_monitor_private_link_scoped_service" "law" {
  name                = "ampls-law-link"
  resource_group_name = var.resource_group_name
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = var.log_analytics_workspace_id
}

resource "azurerm_private_endpoint" "ampls" {
  name                = "${var.workspace_name}-ampls-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.workspace_name}-ampls-psc"
    private_connection_resource_id = azurerm_monitor_private_link_scope.ampls.id
    is_manual_connection           = false
    subresource_names              = ["azuremonitor"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = compact([var.ods_private_dns_zone_id, var.oms_private_dns_zone_id])
  }

  depends_on = [azurerm_monitor_private_link_scoped_service.law]
}
