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
    delegation     = each.value.delegation != null ? each.value.delegation.service_delegation_name : ""
    vnet_name      = var.vnet_name
    resource_group = var.vnet_resource_group_name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      # Add jitter to reduce concurrent writes to the same VNet (AnotherOperationInProgress)
      sleep $((RANDOM % 30 + 5))

      # Check if subnet exists, only create if it doesn't
      if ! az network vnet subnet show \
        --resource-group ${var.vnet_resource_group_name} \
        --vnet-name ${var.vnet_name} \
        --name ${each.key} >/dev/null 2>&1; then

        echo "Creating subnet ${each.key}..."

        # Retry logic for concurrent VNet operation errors (using while loop for sh compatibility)
        i=1
        while [ $i -le 8 ]; do
          if az network vnet subnet create \
            --name ${each.key} \
            --resource-group ${var.vnet_resource_group_name} \
            --vnet-name ${var.vnet_name} \
            --address-prefix ${each.value.address_prefix} \
            ${each.value.create_nsg ? "--network-security-group ${azurerm_network_security_group.nsg[each.key].id}" : ""} \
            ${each.value.delegation != null ? "--delegations ${each.value.delegation.service_delegation_name}" : ""} \
            --private-endpoint-network-policies ${each.value.private_endpoint_network_policies} \
            ${each.value.default_outbound_access_enabled ? "--default-outbound true" : "--default-outbound false"} 2>&1; then
            echo "✓ Subnet ${each.key} created successfully"
            break
          else
            if [ $i -lt 8 ]; then
              echo "Retry $i/8: Waiting before retry due to concurrent operation..."
              sleep $((RANDOM % 30 + 20))
              i=$((i + 1))
            else
              echo "Failed to create subnet ${each.key} after 8 attempts"
              exit 1
            fi
          fi
        done
      else
        echo "Subnet ${each.key} already exists, updating if needed..."

        # Retry update as well to handle AnotherOperationInProgress on existing subnets
        i=1
        while [ $i -le 8 ]; do
          if az network vnet subnet update \
            --resource-group ${var.vnet_resource_group_name} \
            --vnet-name ${var.vnet_name} \
            --name ${each.key} \
            ${each.value.create_nsg ? "--network-security-group ${azurerm_network_security_group.nsg[each.key].id}" : ""} \
            ${each.value.delegation != null ? "--delegations ${each.value.delegation.service_delegation_name}" : ""} \
            --private-endpoint-network-policies ${each.value.private_endpoint_network_policies} 2>&1; then
            echo "✓ Subnet ${each.key} updated successfully"
            break
          else
            if [ $i -lt 8 ]; then
              echo "Retry $i/8: Waiting before retry due to concurrent operation..."
              sleep $((RANDOM % 30 + 20))
              i=$((i + 1))
            else
              echo "Failed to update subnet ${each.key} after 8 attempts"
              exit 1
            fi
          fi
        done
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
# Diagnostic settings for NSGs
# ------------------------------------------------------------------------------
# Uses az CLI instead of azurerm provider so that destroy tolerates a
# CanNotDelete lock on the platform VNet RG (|| true on delete).
resource "null_resource" "nsg_diagnostics" {
  for_each = var.enable_diagnostic_settings ? { for k, v in var.subnets : k => v if v.create_nsg } : {}

  triggers = {
    diag_name = "diag-${each.value.nsg_name != null ? each.value.nsg_name : "nsg-${each.key}"}"
    nsg_id    = azurerm_network_security_group.nsg[each.key].id
    law_id    = var.log_analytics_workspace_id
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      az monitor diagnostic-settings create \
        --name "${self.triggers.diag_name}" \
        --resource "${self.triggers.nsg_id}" \
        --workspace "${self.triggers.law_id}" \
        --logs '[{"category":"NetworkSecurityGroupEvent","enabled":true},{"category":"NetworkSecurityGroupRuleCounter","enabled":true}]'
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      az monitor diagnostic-settings delete \
        --name "${self.triggers.diag_name}" \
        --resource "${self.triggers.nsg_id}" 2>/dev/null || true
    EOT
  }

  depends_on = [azurerm_network_security_group.nsg]
}
