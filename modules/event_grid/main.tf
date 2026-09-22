resource "azurerm_resource_group" "event_grid" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_eventgrid_topic" "event_grid" {
  name                          = var.topic_name
  location                      = var.location
  resource_group_name           = azurerm_resource_group.event_grid.name
  local_auth_enabled            = var.local_auth_enabled
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  # CKV_AZURE_191: managed identity for the topic itself, additive to the existing
  # RBAC role assignments on data_receiver/data_sender/contributor principals below.
  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [tags]
  }

  depends_on = [azurerm_resource_group.event_grid]
}

resource "azurerm_private_endpoint" "event_grid" {
  name                = "pe-${var.topic_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.event_grid.name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.topic_name}-psc"
    private_connection_resource_id = azurerm_eventgrid_topic.event_grid.id
    is_manual_connection           = false
    subresource_names              = ["topic"]
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group, tags]
  }

  depends_on = [azurerm_eventgrid_topic.event_grid]
}

resource "azurerm_role_assignment" "data_receiver" {
  for_each             = toset(var.data_receiver_principal_ids)
  scope                = azurerm_eventgrid_topic.event_grid.id
  role_definition_name = "EventGrid Data Receiver"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "data_sender" {
  for_each             = toset(var.data_sender_principal_ids)
  scope                = azurerm_eventgrid_topic.event_grid.id
  role_definition_name = "EventGrid Data Sender"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "contributor" {
  for_each             = toset(var.contributor_principal_ids)
  scope                = azurerm_eventgrid_topic.event_grid.id
  role_definition_name = "EventGrid Contributor"
  principal_id         = each.value
}

resource "azurerm_monitor_diagnostic_setting" "event_grid" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.topic_name}-diagnostic"
  target_resource_id         = azurerm_eventgrid_topic.event_grid.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
