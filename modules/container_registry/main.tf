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
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.connectivity]
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

  lifecycle {
    prevent_destroy = true
  }
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
  # CKV_AZURE_166: REVERTED 2026-07-27 — quarantine holds every newly pushed image
  # until an external scanner (Qualys/Defender integration) explicitly releases it.
  # No such scanner is wired in this repo, so every image pushed since this was
  # enabled got stuck in quarantine and became unpullable by AKS - this broke the
  # dev team's ability to deploy. Soft-failing this check instead of enabling it
  # blind; re-enable only alongside an actual scanner integration.
  quarantine_policy_enabled = false
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

  lifecycle {
    prevent_destroy = true
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
# Without this, enabling encryption_enabled fails at apply time with 403 when
# ACR tries to use the key.
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
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.acr_name}-psc"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  # NOTE: private_dns_zone_group is intentionally NOT defined here
  # Azure Policy automatically creates the DNS zone group
  # Defining it here causes "MoreThanOnePrivateDnsZoneGroupPerPrivateEndpointNotAllowed" errors

  lifecycle {
    ignore_changes = [
      private_dns_zone_group,
      tags
    ]
  }

  depends_on = [azurerm_container_registry.acr]
}

# Diagnostic settings for ACR
resource "azurerm_monitor_diagnostic_setting" "acr_diagnostic" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.acr_name}-diagnostic"
  target_resource_id         = azurerm_container_registry.acr.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

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
