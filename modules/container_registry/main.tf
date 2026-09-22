# ==============================================================================
# Container Registry Module
# ==============================================================================
# Creates Azure Container Registry with:
# - Private endpoint connectivity
# - Optional customer-managed encryption
# - Diagnostic monitoring
# ==============================================================================

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

# ------------------------------------------------------------------------------
# Resource Group
# ------------------------------------------------------------------------------
resource "azurerm_resource_group" "acr" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ------------------------------------------------------------------------------
# Container Registry
# ------------------------------------------------------------------------------
resource "azurerm_container_registry" "acr" {
  name                          = var.acr_name
  location                      = var.location
  resource_group_name           = azurerm_resource_group.acr.name
  sku                           = var.sku
  anonymous_pull_enabled        = var.anonymous_pull_enabled
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled
  zone_redundancy_enabled       = var.sku == "Premium" ? var.zone_redundancy_enabled : false
  # CKV_AZURE_167/237: retention policy and dedicated data endpoints are
  # Premium-only and safe to enable unconditionally on Premium - neither
  # changes push/pull behavior.
  #
  # CKV_AZURE_166 (quarantine policy) is deliberately NOT enabled the same
  # way. Quarantine holds every pushed image in a locked, unpullable state
  # until an external scanning integration explicitly marks it as passed -
  # without that integration wired up, every image pushed to the registry
  # becomes permanently stuck and undeployable. This codebase does not
  # provide that integration, so quarantine defaults off; only enable
  # var.quarantine_policy_enabled if you have a scanning pipeline that
  # clears quarantined images.
  quarantine_policy_enabled = var.sku == "Premium" && var.quarantine_policy_enabled
  retention_policy_in_days  = var.sku == "Premium" && var.retention_policy_enabled ? var.retention_policy_days : null
  data_endpoint_enabled     = var.sku == "Premium"
  tags                      = var.tags

  identity {
    type = var.encryption_enabled ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.encryption_enabled ? [
      azurerm_user_assigned_identity.acr[0].id
    ] : null
  }

  dynamic "encryption" {
    for_each = var.encryption_enabled && var.key_vault_key_id != null ? [1] : []
    content {
      key_vault_key_id   = var.key_vault_key_id
      identity_client_id = azurerm_user_assigned_identity.acr[0].client_id
    }
  }

  # CKV_AZURE_165: geo-replication (Premium SKU only). Empty by default - replicating
  # to another region roughly doubles registry storage cost and requires choosing a
  # target region, so this stays an explicit customer opt-in via var.georeplications.
  dynamic "georeplications" {
    for_each = var.sku == "Premium" ? var.georeplications : {}
    content {
      location                  = georeplications.value.location
      zone_redundancy_enabled   = georeplications.value.zone_redundancy_enabled
      regional_endpoint_enabled = true
      tags                      = var.tags
    }
  }

  depends_on = [azurerm_role_assignment.acr_cmk]
}

# ------------------------------------------------------------------------------
# Managed Identity (for encryption)
# ------------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "acr" {
  count               = var.encryption_enabled ? 1 : 0
  name                = "${var.acr_name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Grants the ACR encryption identity permission to wrap/unwrap the CMK.
# Without this, enabling encryption_enabled fails at apply time with 403
# when ACR tries to use the key.
resource "azurerm_role_assignment" "acr_cmk" {
  count                = var.encryption_enabled && var.key_vault_id != null ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.acr[0].principal_id
}

# ------------------------------------------------------------------------------
# Private Endpoint
# ------------------------------------------------------------------------------
resource "azurerm_private_endpoint" "acr" {
  name                = "${var.acr_name}-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.acr.name
  subnet_id           = data.azurerm_subnet.acr.id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.acr_name}-psc"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.acr_private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.acr_private_dns_zone_id]
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
      subnet_id
    ]
  }

  depends_on = [azurerm_container_registry.acr]
}

# Diagnostic settings for ACR
resource "azurerm_monitor_diagnostic_setting" "acr_diagnostic" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.acr_name}-diagnostic"
  target_resource_id         = azurerm_container_registry.acr.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_analytics.id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# Scope map for token authentication (optional)
resource "azurerm_container_registry_scope_map" "pull" {
  count                   = var.create_scope_maps ? 1 : 0
  name                    = "pull-scope"
  container_registry_name = azurerm_container_registry.acr.name
  resource_group_name     = var.resource_group_name
  actions = [
    "repositories/*/content/read",
    "repositories/*/metadata/read"
  ]
}

resource "azurerm_container_registry_scope_map" "push" {
  count                   = var.create_scope_maps ? 1 : 0
  name                    = "push-scope"
  container_registry_name = azurerm_container_registry.acr.name
  resource_group_name     = var.resource_group_name
  actions = [
    "repositories/*/content/read",
    "repositories/*/content/write",
    "repositories/*/metadata/read",
    "repositories/*/metadata/write"
  ]
}

# Webhook for container events (optional)
resource "azurerm_container_registry_webhook" "acr_webhook" {
  for_each            = var.webhooks
  name                = each.key
  resource_group_name = var.resource_group_name
  registry_name       = azurerm_container_registry.acr.name
  location            = var.location
  service_uri         = each.value.service_uri
  status              = each.value.status
  scope               = each.value.scope
  actions             = each.value.actions
  custom_headers      = each.value.custom_headers
  tags                = var.tags
}
