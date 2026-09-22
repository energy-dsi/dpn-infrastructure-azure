resource "azurerm_resource_group" "service_bus" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_servicebus_namespace" "service_bus" {
  name                          = var.namespace_name
  location                      = var.location
  resource_group_name           = azurerm_resource_group.service_bus.name
  sku                           = var.sku
  capacity                      = var.capacity
  premium_messaging_partitions  = var.premium_messaging_partitions
  public_network_access_enabled = var.public_network_access_enabled
  minimum_tls_version           = var.minimum_tls_version
  local_auth_enabled            = var.local_auth_enabled
  tags                          = var.tags

  dynamic "identity" {
    for_each = [1]
    content {
      type         = var.encryption_enabled ? "SystemAssigned, UserAssigned" : "SystemAssigned"
      identity_ids = var.encryption_enabled ? [azurerm_user_assigned_identity.service_bus_cmk[0].id] : null
    }
  }

  dynamic "customer_managed_key" {
    # CMK requires Premium SKU (azurerm/Azure platform requirement).
    for_each = var.encryption_enabled && var.sku == "Premium" && var.key_vault_key_id != null ? [1] : []
    content {
      key_vault_key_id                  = var.key_vault_key_id
      identity_id                       = azurerm_user_assigned_identity.service_bus_cmk[0].id
      infrastructure_encryption_enabled = true
    }
  }

  dynamic "network_rule_set" {
    for_each = var.trusted_services_allowed ? [1] : []
    content {
      public_network_access_enabled = false
      trusted_services_allowed      = true
    }
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [tags]
  }

  depends_on = [azurerm_resource_group.service_bus, azurerm_role_assignment.service_bus_cmk]
}

# ------------------------------------------------------------------------------
# Customer-managed key support (Premium SKU only)
# ------------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "service_bus_cmk" {
  count               = var.encryption_enabled ? 1 : 0
  name                = "${var.namespace_name}-cmk"
  location            = var.location
  resource_group_name = azurerm_resource_group.service_bus.name
  tags                = var.tags
}

# Grants the namespace encryption identity permission to wrap/unwrap the CMK.
# Without this, enabling encryption_enabled fails at apply time with 403 when
# Service Bus tries to use the key.
resource "azurerm_role_assignment" "service_bus_cmk" {
  count                = var.encryption_enabled && var.key_vault_id != null ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.service_bus_cmk[0].principal_id
}

resource "azurerm_servicebus_queue" "queues" {
  for_each     = var.queues
  name         = each.key
  namespace_id = azurerm_servicebus_namespace.service_bus.id

  max_size_in_megabytes = each.value.max_size_in_megabytes
  default_message_ttl   = each.value.default_message_ttl
  lock_duration         = each.value.lock_duration
}

resource "azurerm_private_endpoint" "service_bus" {
  name                = "pe-${var.namespace_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.service_bus.name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.namespace_name}-psc"
    private_connection_resource_id = azurerm_servicebus_namespace.service_bus.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group, tags]
  }

  depends_on = [azurerm_servicebus_namespace.service_bus]
}

resource "azurerm_role_assignment" "data_receiver" {
  for_each             = toset(var.data_receiver_principal_ids)
  scope                = azurerm_servicebus_namespace.service_bus.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "data_sender" {
  for_each             = toset(var.data_sender_principal_ids)
  scope                = azurerm_servicebus_namespace.service_bus.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "data_owner" {
  for_each             = toset(var.data_owner_principal_ids)
  scope                = azurerm_servicebus_namespace.service_bus.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = each.value
}

resource "azurerm_monitor_diagnostic_setting" "service_bus" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.namespace_name}-diagnostic"
  target_resource_id         = azurerm_servicebus_namespace.service_bus.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
