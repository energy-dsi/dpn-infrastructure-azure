terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

# ========================================
# Event Grid Custom Topic Module
# ========================================
# public_network_access_enabled defaults to true. A private endpoint is also
# always deployed, but if this topic receives Microsoft Defender for Storage
# malware-scan-result events, public access must stay enabled - Defender for
# Storage cannot deliver those events to a topic restricted to a private
# endpoint only (confirmed Microsoft/platform limitation, not a config bug).
# If this topic does NOT receive Defender for Storage events, set this to
# false via var.public_network_access_enabled.

resource "azurerm_resource_group" "event_grid" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_eventgrid_topic" "topic" {
  name                          = var.topic_name
  location                      = var.location
  resource_group_name           = azurerm_resource_group.event_grid.name
  public_network_access_enabled = var.public_network_access_enabled
  local_auth_enabled            = var.local_auth_enabled
  tags                          = var.tags

  # CKV_AZURE_191: managed identity for the topic itself, additive to the existing
  # RBAC role assignments on data_receiver/data_sender/contributor principals below.
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "topic" {
  name                = "${var.topic_name}-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.event_grid.name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.topic_name}-psc"
    private_connection_resource_id = azurerm_eventgrid_topic.topic.id
    is_manual_connection           = false
    subresource_names              = ["topic"]
  }

  dynamic "private_dns_zone_group" {
    for_each = (var.private_dns_zone_id != null && var.private_dns_zone_id != "") ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  lifecycle {
    ignore_changes = [tags]
  }

  depends_on = [azurerm_eventgrid_topic.topic]
}

resource "azurerm_role_assignment" "data_receiver" {
  for_each             = toset(var.data_receiver_principal_ids)
  scope                = azurerm_eventgrid_topic.topic.id
  role_definition_name = "EventGrid Data Receiver"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "data_sender" {
  for_each             = toset(var.data_sender_principal_ids)
  scope                = azurerm_eventgrid_topic.topic.id
  role_definition_name = "EventGrid Data Sender"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "contributor" {
  for_each             = toset(var.contributor_principal_ids)
  scope                = azurerm_eventgrid_topic.topic.id
  role_definition_name = "EventGrid Contributor"
  principal_id         = each.value
}

resource "azurerm_monitor_diagnostic_setting" "event_grid_diagnostic" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.topic_name}-diagnostic"
  target_resource_id         = azurerm_eventgrid_topic.topic.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_metric {
    category = "AllMetrics"
  }
}
