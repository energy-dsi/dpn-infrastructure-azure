terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

# ========================================
# Azure Bastion Module
# ========================================
# Deploys Azure Bastion as the RDP access path into an air-gapped VNet, so
# operators can reach the Windows jump host (and, once on it, the AKS
# cluster and anything else reachable only via private endpoint).
#
# Developer SKU (var.sku == "Developer") attaches directly to the VNet via
# virtual_network_id — no dedicated AzureBastionSubnet, no NSG, no public IP
# at all. This matches the pattern already used elsewhere in the org (e.g.
# vnet-dpn-dev-uks-01-bastion) and avoids the AzureBastionSubnet NSG
# entirely, so it isn't subject to NSG-level policies like Deny-Nsg-Any-Any.
# Basic/Standard/Premium instead use a dedicated AzureBastionSubnet + public
# IP via subnet_id — see docs/Pipeline-Configuration.md for the full history.

resource "azurerm_resource_group" "bastion" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_public_ip" "bastion" {
  count               = var.sku == "Developer" ? 0 : 1
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = azurerm_resource_group.bastion.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = length(var.zones) > 0 ? var.zones : null
  tags                = var.tags
}

resource "azurerm_bastion_host" "bastion" {
  name                = var.bastion_host_name
  location            = var.location
  resource_group_name = azurerm_resource_group.bastion.name
  sku                 = var.sku
  zones               = contains(["Standard", "Premium"], var.sku) && length(var.zones) > 0 ? var.zones : null
  tags                = var.tags

  # scale_units, file_copy, tunneling, shareable_link and zones all require Standard or Premium;
  # Developer SKU is a single-session, no-scaling deployment with none of these options.
  scale_units            = contains(["Standard", "Premium"], var.sku) ? var.scale_units : null
  copy_paste_enabled     = var.copy_paste_enabled
  file_copy_enabled      = contains(["Standard", "Premium"], var.sku) ? var.file_copy_enabled : false
  tunneling_enabled      = contains(["Standard", "Premium"], var.sku) ? var.tunneling_enabled : false
  shareable_link_enabled = contains(["Standard", "Premium"], var.sku) ? var.shareable_link_enabled : false
  ip_connect_enabled     = var.sku == "Premium" ? var.ip_connect_enabled : false
  kerberos_enabled       = var.kerberos_enabled

  # Developer SKU: attaches to the VNet directly, no subnet/public IP.
  virtual_network_id = var.sku == "Developer" ? var.virtual_network_id : null

  dynamic "ip_configuration" {
    for_each = var.sku == "Developer" ? [] : [1]
    content {
      name                 = "bastion-ip-config"
      subnet_id            = var.subnet_id
      public_ip_address_id = azurerm_public_ip.bastion[0].id
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "bastion_diagnostic" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.bastion_host_name}-diagnostic"
  target_resource_id         = azurerm_bastion_host.bastion.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
