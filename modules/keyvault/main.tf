# ==============================================================================
# Key Vault Module
# ==============================================================================
# Creates Azure Key Vault with:
# - RBAC authorization
# - Private endpoint connectivity
# - Diagnostic monitoring
# - Network access controls
# ==============================================================================

terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.connectivity]
    }
  }
}

locals {
  sandbox_subscription = can(regex("sbx", data.azurerm_subscription.current.display_name))
}

# ------------------------------------------------------------------------------
# Resource Group
# ------------------------------------------------------------------------------
resource "azurerm_resource_group" "keyvault" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# ------------------------------------------------------------------------------
# Key Vault
# ------------------------------------------------------------------------------
resource "azurerm_key_vault" "keyvault" {
  name                            = var.keyvault_name
  location                        = var.location
  resource_group_name             = azurerm_resource_group.keyvault.name
  sku_name                        = var.keyvault_sku_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days      = var.soft_delete_retention_days
  purge_protection_enabled        = var.purge_protection_enabled
  rbac_authorization_enabled      = var.rbac_authorization_enabled
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment
  public_network_access_enabled   = var.public_network_access_enabled
  tags                            = var.tags

  dynamic "network_acls" {
    for_each = var.network_acls_enabled ? [1] : []
    content {
      bypass                     = var.network_acls_bypass
      default_action             = var.network_acls_default_action
      ip_rules                   = var.allowed_ip_ranges
      virtual_network_subnet_ids = var.allowed_subnet_ids
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

# ------------------------------------------------------------------------------
# Private Endpoint
# ------------------------------------------------------------------------------
resource "azurerm_private_endpoint" "keyvault" {
  name                = "${var.keyvault_name}-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.keyvault.name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.keyvault_name}-psc"
    private_connection_resource_id = azurerm_key_vault.keyvault.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  # Do not define DNS zone group - Azure Policy will add it automatically
  # Terraform will ignore changes to it

  lifecycle {
    ignore_changes = [
      private_dns_zone_group,
      tags
    ]
  }

  depends_on = [azurerm_key_vault.keyvault]
}

# Diagnostic settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "keyvault_diagnostic" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.keyvault_name}-diag"
  target_resource_id         = azurerm_key_vault.keyvault.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# RBAC role assignments for Key Vault
resource "azurerm_role_assignment" "keyvault_admin" {
  for_each             = toset(var.key_vault_admin_object_ids)
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "keyvault_secrets_officer" {
  for_each             = toset(var.key_vault_secrets_officer_object_ids)
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "keyvault_secrets_user" {
  for_each             = toset(var.key_vault_secrets_user_object_ids)
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

# Optional: Create example secrets
resource "azurerm_key_vault_secret" "secrets" {
  for_each     = var.initial_secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.keyvault.id
  content_type = "text/plain"

  depends_on = [
    azurerm_role_assignment.keyvault_admin,
    azurerm_role_assignment.keyvault_secrets_officer
  ]
}

# Optional: Create example keys with rotation policy
resource "azurerm_key_vault_key" "keys" {
  for_each     = var.initial_keys
  name         = each.key
  key_vault_id = azurerm_key_vault.keyvault.id
  key_type     = each.value.key_type
  key_size     = each.value.key_size
  key_opts     = each.value.key_opts

  dynamic "rotation_policy" {
    for_each = each.value.enable_rotation ? [1] : []
    content {
      automatic {
        time_before_expiry = each.value.rotation_time_before_expiry
      }

      expire_after         = each.value.rotation_expire_after
      notify_before_expiry = each.value.rotation_notify_before_expiry
    }
  }

  depends_on = [
    azurerm_role_assignment.keyvault_admin
  ]
}

# Optional: self-signed certificates (e.g. a Notation image-signing certificate).
# Notation's standard signing model needs a leaf certificate, not a bare key - this is
# separate from initial_keys above for that reason. Self-signed matches this codebase's
# existing convention for internal trust.
resource "azurerm_key_vault_certificate" "certificates" {
  for_each     = var.initial_certificates
  name         = each.key
  key_vault_id = azurerm_key_vault.keyvault.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }
    key_properties {
      exportable = each.value.exportable
      key_type   = each.value.key_type
      key_size   = each.value.key_size
      reuse_key  = false
    }
    lifetime_action {
      action {
        action_type = "AutoRenew"
      }
      trigger {
        days_before_expiry = each.value.renew_days_before_expiry
      }
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    x509_certificate_properties {
      key_usage          = each.value.key_usage
      subject            = each.value.subject
      validity_in_months = each.value.validity_in_months
    }
  }

  depends_on = [
    azurerm_role_assignment.keyvault_admin
  ]
}
