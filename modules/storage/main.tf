# ========================================
# Storage Account Module for Developer Use
# ========================================

resource "azurerm_resource_group" "storage" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags

  lifecycle {
    prevent_destroy = true
  }
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
  https_traffic_only_enabled        = var.enable_https_traffic_only
  shared_access_key_enabled         = var.shared_access_key_enabled
  infrastructure_encryption_enabled = true # CKV2_AZURE_18: double-layer encryption at rest
  is_hns_enabled                    = var.is_hns_enabled
  local_user_enabled                = false # CKV_AZURE_244: local users/SFTP not used; access is via AAD/RBAC role assignments only
  large_file_share_enabled          = var.large_file_share_enabled
  tags                              = var.tags

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

  blob_properties {
    versioning_enabled = var.versioning_enabled

    delete_retention_policy {
      days = var.blob_retention_days
    }

    container_delete_retention_policy {
      days = var.container_retention_days
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

  lifecycle {
    prevent_destroy = true
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
# Without this, enabling encryption_enabled fails at apply time with 403 when
# Storage tries to use the key.
resource "azurerm_role_assignment" "storage_cmk" {
  count                = var.encryption_enabled && var.key_vault_id != null ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.storage_cmk[0].principal_id
}

resource "azurerm_storage_share" "file_share" {
  count              = var.file_share_name != "" ? 1 : 0
  name               = var.file_share_name
  storage_account_id = azurerm_storage_account.storage.id
  quota              = var.file_share_quota_gb

  depends_on = [azurerm_storage_account.storage]
}

# Grant Storage Blob Data Contributor role to dev team SPN
resource "azurerm_role_assignment" "blob_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.dev_team_spn_object_id
}

resource "azurerm_role_assignment" "additional_blob_contributor" {
  for_each             = toset(var.additional_blob_contributor_principal_ids)
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
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

  # NOTE: private_dns_zone_group is intentionally NOT defined here
  # Azure Policy automatically creates the DNS zone group
  # Defining it here causes "MoreThanOnePrivateDnsZoneGroupPerPrivateEndpointNotAllowed" errors

  lifecycle {
    ignore_changes = [
      private_dns_zone_group,
      tags
    ]
  }

  depends_on = [azurerm_storage_account.storage]
}

# Private Endpoint for Azure Files
resource "azurerm_private_endpoint" "file" {
  count               = var.create_file_endpoint && var.file_share_name != "" ? 1 : 0
  name                = "pe-${var.storage_account_name}-file"
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

  # NOTE: private_dns_zone_group is intentionally NOT defined here
  # Azure Policy automatically creates the DNS zone group
  # Defining it here causes "MoreThanOnePrivateDnsZoneGroupPerPrivateEndpointNotAllowed" errors

  lifecycle {
    ignore_changes = [
      private_dns_zone_group,
      tags
    ]
  }

  depends_on = [azurerm_storage_account.storage, azurerm_storage_share.file_share]
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "storage_diagnostic" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.storage_account_name}-diagnostic"
  target_resource_id         = azurerm_storage_account.storage.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_metric {
    category = "Capacity"
  }

  enabled_metric {
    category = "Transaction"
  }
}
