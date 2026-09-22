# ==============================================================================
# Networking Module
# ==============================================================================
# Creates subnets and network security groups in an existing VNet
# ==============================================================================

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

# ------------------------------------------------------------------------------
# Network Security Groups
# ------------------------------------------------------------------------------
# NSGs must be created BEFORE subnets due to Azure Policy requiring
# NSGs to be attached atomically during subnet creation
# NSG naming convention: nsg-<project>-<env>-<location>-<purpose>-<number>
resource "azurerm_network_security_group" "nsg" {
  for_each            = { for k, v in var.subnets : k => v if v.create_nsg }
  name                = each.value.nsg_name != null ? each.value.nsg_name : "nsg-${var.project_name}-${var.environment}-${var.location_short}-${each.key}-${var.instance_number}"
  location            = var.location
  resource_group_name = var.vnet_resource_group_name
  tags                = var.tags
}

# ------------------------------------------------------------------------------
# Subnets with NSG attached via local-exec
# ------------------------------------------------------------------------------
# Using null_resource with Azure CLI to create subnets with NSG attached
# This works around Azure Policy that requires atomic NSG attachment
# Subnets are created with explicit dependencies to avoid concurrent operations
resource "null_resource" "subnet_with_nsg" {
  for_each = var.subnets

  triggers = {
    subnet_name    = each.key
    address_prefix = each.value.address_prefix
    nsg_id         = each.value.create_nsg ? azurerm_network_security_group.nsg[each.key].id : ""
    vnet_name      = var.vnet_name
    resource_group = var.vnet_resource_group_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Wait a few seconds to avoid concurrent operations on VNet
      sleep $((RANDOM % 5 + 2))

      # Check if subnet exists, only create if it doesn't
      if ! az network vnet subnet show \
        --resource-group ${var.vnet_resource_group_name} \
        --vnet-name ${var.vnet_name} \
        --name ${each.key} &>/dev/null; then

        echo "Creating subnet ${each.key}..."

        # Retry logic for concurrent operation errors (using while loop for sh compatibility)
        i=1
        while [ $i -le 5 ]; do
          if az network vnet subnet create \
            --name ${each.key} \
            --resource-group ${var.vnet_resource_group_name} \
            --vnet-name ${var.vnet_name} \
            --address-prefix ${each.value.address_prefix} \
            ${each.value.create_nsg ? "--network-security-group ${azurerm_network_security_group.nsg[each.key].id}" : ""} \
            --private-endpoint-network-policies ${each.value.private_endpoint_network_policies} \
            ${each.value.delegation != null ? "--delegations ${each.value.delegation.service_delegation_name}" : ""} \
            ${each.value.default_outbound_access_enabled ? "--default-outbound true" : "--default-outbound false"} 2>&1; then
            echo "✓ Subnet ${each.key} created successfully"
            break
          else
            if [ $i -lt 5 ]; then
              echo "Retry $i/5: Waiting 30 seconds before retry..."
              sleep 30
              i=$((i + 1))
            else
              echo "Failed to create subnet ${each.key} after 5 attempts"
              exit 1
            fi
          fi
        done
      else
        echo "Subnet ${each.key} already exists, updating if needed..."
        az network vnet subnet update \
          --resource-group ${var.vnet_resource_group_name} \
          --vnet-name ${var.vnet_name} \
          --name ${each.key} \
          ${each.value.create_nsg ? "--network-security-group ${azurerm_network_security_group.nsg[each.key].id}" : ""} \
          --private-endpoint-network-policies ${each.value.private_endpoint_network_policies} \
          ${each.value.delegation != null ? "--delegations ${each.value.delegation.service_delegation_name}" : ""}
      fi
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      az network vnet subnet delete \
        --name ${self.triggers.subnet_name} \
        --resource-group ${self.triggers.resource_group} \
        --vnet-name ${self.triggers.vnet_name} || true
    EOT
  }

  depends_on = [azurerm_network_security_group.nsg]
}

# Reference the created subnets as data sources
# Subnets are created by null_resource above, we just reference them here
data "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.vnet_resource_group_name
  virtual_network_name = var.vnet_name

  depends_on = [null_resource.subnet_with_nsg]
}

# ------------------------------------------------------------------------------
# NSG Rules
# ------------------------------------------------------------------------------
resource "azurerm_network_security_rule" "nsg_rules" {
  for_each = merge([
    for subnet_key, subnet in var.subnets : {
      for rule_key, rule in subnet.nsg_rules : "${subnet_key}-${rule_key}" => merge(rule, {
        nsg_name            = subnet.nsg_name != null ? subnet.nsg_name : "nsg-${subnet_key}"
        resource_group_name = var.vnet_resource_group_name
      })
    } if subnet.create_nsg
  ]...)

  name                        = split("-", each.key)[1]
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = each.value.resource_group_name
  network_security_group_name = each.value.nsg_name

  depends_on = [azurerm_network_security_group.nsg]
}

# ------------------------------------------------------------------------------
# Route Tables
# ------------------------------------------------------------------------------
resource "azurerm_route_table" "route_table" {
  for_each            = { for k, v in var.subnets : k => v if v.route_table != null }
  name                = each.value.route_table.name
  location            = var.location
  resource_group_name = var.vnet_resource_group_name
  tags                = var.tags
}

resource "azurerm_route" "routes" {
  for_each = merge([
    for subnet_key, subnet in var.subnets : {
      for route_key, route in try(subnet.route_table.routes, {}) : "${subnet_key}-${route_key}" => merge(route, {
        subnet_key = subnet_key
        route_key  = route_key
      })
    } if subnet.route_table != null
  ]...)

  name                   = each.value.route_key
  resource_group_name    = var.vnet_resource_group_name
  route_table_name       = azurerm_route_table.route_table[each.value.subnet_key].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = try(each.value.next_hop_in_ip_address, null)
}

resource "azurerm_subnet_route_table_association" "route_table_association" {
  for_each       = { for k, v in var.subnets : k => v if v.route_table != null }
  subnet_id      = data.azurerm_subnet.subnets[each.key].id
  route_table_id = azurerm_route_table.route_table[each.key].id

  depends_on = [azurerm_route.routes]
}

# ------------------------------------------------------------------------------
# Diagnostic settings for NSGs
# ------------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "nsg_diagnostics" {
  for_each                   = var.enable_diagnostic_settings ? { for k, v in var.subnets : k => v if v.create_nsg } : {}
  name                       = "diag-${each.value.nsg_name != null ? each.value.nsg_name : "nsg-${each.key}"}"
  target_resource_id         = azurerm_network_security_group.nsg[each.key].id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_analytics[0].id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
