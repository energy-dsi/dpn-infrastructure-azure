# ========================================
# Storage Account Module for Developer Use
# ========================================

resource "azurerm_resource_group" "storage" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "storage" {
  name                              = var.storage_account_name
  resource_group_name               = azurerm_resource_group.storage.name
  location                          = var.location
  account_tier                      = var.account_tier
  account_replication_type          = var.replication_type
  account_kind                      = var.account_kind
  access_tier                       = var.access_tier
  public_network_access_enabled     = var.public_network_access_enabled
  allow_nested_items_to_be_public   = var.allow_nested_items_to_be_public
  min_tls_version                   = var.min_tls_version
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  https_traffic_only_enabled        = var.enable_https_traffic_only
  shared_access_key_enabled         = var.shared_access_key_enabled
  local_user_enabled                = false # CKV_AZURE_244: local users/SFTP not used; access is via AAD/RBAC role assignments only
  is_hns_enabled                    = var.is_hns_enabled
  large_file_share_enabled          = var.large_file_share_enabled
  tags                              = var.tags

  blob_properties {
    versioning_enabled = var.versioning_enabled

    delete_retention_policy {
      days = var.blob_retention_days
    }

    container_delete_retention_policy {
      days = var.container_retention_days
    }
  }

  dynamic "queue_properties" {
    for_each = var.queue_logging_enabled ? [1] : []
    content {
      logging {
        delete                = true
        read                  = true
        write                 = true
        version               = "1.0"
        retention_policy_days = 7
      }
    }
  }

  network_rules {
    default_action             = var.network_rules_default_action
    bypass                     = var.network_rules_bypass
    ip_rules                   = var.network_rules_ip_rules
    virtual_network_subnet_ids = var.network_rules_subnet_ids
  }

  # CKV2_AZURE_41: bound the lifetime of account-level SAS tokens.
  # expiration_action = "Log" only flags violations rather than blocking existing
  # developer-tooling workflows that rely on shared_access_key_enabled.
  sas_policy {
    expiration_period = var.sas_expiration_period
    expiration_action = "Log"
  }

  dynamic "identity" {
    for_each = var.encryption_enabled ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.storage_cmk[0].id]
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.encryption_enabled && var.key_vault_key_id != null ? [1] : []
    content {
      key_vault_key_id          = var.key_vault_key_id
      user_assigned_identity_id = azurerm_user_assigned_identity.storage_cmk[0].id
    }
  }

  depends_on = [azurerm_role_assignment.storage_cmk]
}

# ------------------------------------------------------------------------------
# Customer-managed key support
# ------------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "storage_cmk" {
  count               = var.encryption_enabled ? 1 : 0
  name                = "${var.storage_account_name}-cmk"
  location            = var.location
  resource_group_name = azurerm_resource_group.storage.name
  tags                = var.tags
}

# Grants the storage encryption identity permission to wrap/unwrap the CMK.
# Without this, enabling encryption_enabled fails at apply time with 403
# when Storage tries to use the key.
resource "azurerm_role_assignment" "storage_cmk" {
  count                = var.encryption_enabled && var.key_vault_id != null ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.storage_cmk[0].principal_id
}

# Grant Storage Blob Data Contributor role to dev team SPN
resource "azurerm_role_assignment" "blob_contributor" {
  count                = var.dev_team_spn_object_id != "" ? 1 : 0
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.dev_team_spn_object_id
}

# Grant Storage Blob Data Contributor role to additional principal IDs
resource "azurerm_role_assignment" "blob_contributor_additional" {
  for_each             = toset(var.blob_contributor_additional_principal_ids)
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

# Grant Storage Blob Data Reader role to specified principal IDs
resource "azurerm_role_assignment" "blob_reader" {
  for_each             = toset(var.blob_reader_principal_ids)
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}

# Private Endpoint for Blob
resource "azurerm_private_endpoint" "blob" {
  count               = var.create_blob_endpoint ? 1 : 0
  name                = "${var.storage_account_name}-blob-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.storage.name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.storage_account_name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  dynamic "private_dns_zone_group" {
    for_each = (var.blob_private_dns_zone_id != null && var.blob_private_dns_zone_id != "") ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.blob_private_dns_zone_id]
    }
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

  depends_on = [azurerm_storage_account.storage]
}

# Azure Files share
resource "azurerm_storage_share" "share" {
  count              = var.create_file_share ? 1 : 0
  name               = var.file_share_name
  storage_account_id = azurerm_storage_account.storage.id
  quota              = var.file_share_quota_gb
}

# Private Endpoint for File (Azure Files)
resource "azurerm_private_endpoint" "file" {
  count               = var.create_file_endpoint ? 1 : 0
  name                = "${var.storage_account_name}-file-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.storage.name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.storage_account_name}-file-psc"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  dynamic "private_dns_zone_group" {
    for_each = (var.file_private_dns_zone_id != null && var.file_private_dns_zone_id != "") ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.file_private_dns_zone_id]
    }
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

  depends_on = [azurerm_storage_account.storage]
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "storage_diagnostic" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.storage_account_name}-diagnostic"
  target_resource_id         = azurerm_storage_account.storage.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_metric {
    category = "AllMetrics"
  }
}
