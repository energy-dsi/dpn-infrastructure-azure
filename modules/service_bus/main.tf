terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

# ========================================
# Azure Service Bus Namespace Module
# ========================================

resource "azurerm_resource_group" "service_bus" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_servicebus_namespace" "namespace" {
  name                          = var.namespace_name
  location                      = var.location
  resource_group_name           = azurerm_resource_group.service_bus.name
  sku                           = var.sku
  capacity                      = var.sku == "Premium" ? var.capacity : null
  premium_messaging_partitions  = var.sku == "Premium" ? var.premium_messaging_partitions : null
  local_auth_enabled            = var.local_auth_enabled
  minimum_tls_version           = var.minimum_tls_version
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  network_rule_set {
    # default_action must be "Allow" when no ip_rules/network_rules are set (provider validation).
    # public_network_access_enabled controls whether the public endpoint is reachable at all;
    # when true (as in all 4 DPN environments), it's reachable alongside the private endpoint
    # with no IP restriction — add ip_rules here if that needs scoping down later.
    default_action           = "Allow"
    trusted_services_allowed = var.trusted_services_allowed
  }

  dynamic "identity" {
    for_each = var.encryption_enabled ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.service_bus_cmk[0].id]
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

  depends_on = [azurerm_role_assignment.service_bus_cmk]
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
# Without this, enabling encryption_enabled fails at apply time with 403
# when Service Bus tries to use the key.
resource "azurerm_role_assignment" "service_bus_cmk" {
  count                = var.encryption_enabled && var.key_vault_id != null ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.service_bus_cmk[0].principal_id
}

resource "azurerm_private_endpoint" "namespace" {
  name                = "${var.namespace_name}-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.service_bus.name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.namespace_name}-psc"
    private_connection_resource_id = azurerm_servicebus_namespace.namespace.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
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

  depends_on = [azurerm_servicebus_namespace.namespace]
}

resource "azurerm_servicebus_queue" "queues" {
  for_each     = var.queues
  name         = each.key
  namespace_id = azurerm_servicebus_namespace.namespace.id

  max_size_in_megabytes                = lookup(each.value, "max_size_in_megabytes", 1024)
  default_message_ttl                  = lookup(each.value, "default_message_ttl", "P14D")
  lock_duration                        = lookup(each.value, "lock_duration", "PT1M")
  dead_lettering_on_message_expiration = lookup(each.value, "dead_lettering_on_message_expiration", false)
  max_delivery_count                   = lookup(each.value, "max_delivery_count", 10)
  requires_duplicate_detection         = lookup(each.value, "requires_duplicate_detection", false)
  requires_session                     = lookup(each.value, "requires_session", false)
  partitioning_enabled                 = lookup(each.value, "partitioning_enabled", false)
}

resource "azurerm_role_assignment" "data_receiver" {
  for_each             = toset(var.data_receiver_principal_ids)
  scope                = azurerm_servicebus_namespace.namespace.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "data_sender" {
  for_each             = toset(var.data_sender_principal_ids)
  scope                = azurerm_servicebus_namespace.namespace.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "data_owner" {
  for_each             = toset(var.data_owner_principal_ids)
  scope                = azurerm_servicebus_namespace.namespace.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = each.value
}

resource "azurerm_monitor_diagnostic_setting" "service_bus_diagnostic" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.namespace_name}-diagnostic"
  target_resource_id         = azurerm_servicebus_namespace.namespace.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "OperationalLogs"
  }

  enabled_log {
    category = "VNetAndIPFilteringLogs"
  }

  enabled_log {
    category = "RuntimeAuditLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
