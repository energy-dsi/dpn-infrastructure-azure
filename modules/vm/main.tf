# ========================================
# Windows Virtual Machine Module
# ========================================

# Resource Group
resource "azurerm_resource_group" "vm" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Network Interface
resource "azurerm_network_interface" "vm" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_allocation
    private_ip_address            = var.private_ip_allocation == "Static" ? var.private_ip_address : null
  }
}

# Network Security Group (if enabled)
resource "azurerm_network_security_group" "vm" {
  count               = var.create_nsg ? 1 : 0
  name                = "${var.vm_name}-nsg"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  tags                = var.tags
}

# NSG Association
resource "azurerm_network_interface_security_group_association" "vm" {
  count                     = var.create_nsg ? 1 : 0
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.vm[0].id
}

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                       = var.vm_name
  computer_name              = var.computer_name
  location                   = azurerm_resource_group.vm.location
  resource_group_name        = azurerm_resource_group.vm.name
  size                       = var.vm_size
  admin_username             = var.admin_username
  admin_password             = var.admin_password
  allow_extension_operations = var.allow_extension_operations
  tags                       = var.tags

  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  os_disk {
    name                   = "${var.vm_name}-osdisk"
    caching                = var.os_disk_caching
    storage_account_type   = var.os_disk_storage_account_type
    disk_size_gb           = var.os_disk_size_gb
    disk_encryption_set_id = var.encryption_enabled ? azurerm_disk_encryption_set.vm[0].id : null
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type = var.identity_type
    }
  }

  # Boot diagnostics
  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }

  # Security
  patch_mode                                             = var.patch_mode
  patch_assessment_mode                                  = var.patch_assessment_mode
  bypass_platform_safety_checks_on_user_schedule_enabled = var.bypass_platform_safety_checks_on_user_schedule_enabled
  automatic_updates_enabled                              = var.enable_automatic_updates
  encryption_at_host_enabled                             = var.encryption_at_host_enabled
  secure_boot_enabled                                    = var.secure_boot_enabled
  vtpm_enabled                                           = var.vtpm_enabled
  license_type                                           = var.license_type
  timezone                                               = var.timezone
  zone                                                   = var.availability_zone

  depends_on = [azurerm_role_assignment.disk_encryption_set_cmk]
}

# ------------------------------------------------------------------------------
# Customer-managed key support for the OS disk
# ------------------------------------------------------------------------------
resource "azurerm_disk_encryption_set" "vm" {
  count               = var.encryption_enabled ? 1 : 0
  name                = "${var.vm_name}-des"
  resource_group_name = azurerm_resource_group.vm.name
  location            = azurerm_resource_group.vm.location
  key_vault_key_id    = var.key_vault_key_id
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# Grants the disk encryption set's identity permission to wrap/unwrap the CMK.
# Without this, enabling encryption_enabled fails at apply time with 403
# when the platform tries to use the key.
resource "azurerm_role_assignment" "disk_encryption_set_cmk" {
  count                = var.encryption_enabled ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_disk_encryption_set.vm[0].identity[0].principal_id
}

# Store VM password in Key Vault
# NOTE: Commented out because pipeline agent cannot access Key Vault over network (private infrastructure)
# Password must be stored manually after deployment or retrieved from Azure Portal
# resource "azurerm_key_vault_secret" "vm_password" {
#   name         = "${var.vm_name}-admin-password"
#   value        = var.admin_password
#   key_vault_id = var.key_vault_id
#   tags         = var.tags
#
#   depends_on = [azurerm_windows_virtual_machine.vm]
# }

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "vm" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.vm_name}-diagnostics"
  target_resource_id         = azurerm_windows_virtual_machine.vm.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # VMs don't support log category groups, only metrics
  enabled_metric {
    category = "AllMetrics"
  }
}

# ========================================
# RBAC: Reader on the VM and its NIC
# ========================================
# Required by Azure Bastion to let a principal select this VM in the connect
# flow — Bastion access alone (Reader here) does not authenticate the user
# into Windows; that still requires the VM's own admin credentials.
resource "azurerm_role_assignment" "vm_reader" {
  for_each             = toset(var.reader_principal_ids)
  scope                = azurerm_windows_virtual_machine.vm.id
  role_definition_name = "Reader"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "nic_reader" {
  for_each             = toset(var.reader_principal_ids)
  scope                = azurerm_network_interface.vm.id
  role_definition_name = "Reader"
  principal_id         = each.value
}
