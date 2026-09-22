# ==============================================================================
# Log Analytics Module
# ==============================================================================
# Creates Log Analytics workspace with:
# - Private link scope for secure access
# - Private DNS zones for monitor endpoints
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
resource "azurerm_resource_group" "log_analytics" {
  name     = var.log_analytics_resource_group_name
  location = var.location
  tags     = var.tags
}

# ------------------------------------------------------------------------------
# Log Analytics Workspace
# ------------------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = azurerm_resource_group.log_analytics.name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  tags                = var.tags

  depends_on = [azurerm_resource_group.log_analytics]

  identity {
    type = var.identity_type
  }
}

# Note: AMPLS (Azure Monitor Private Link Scope) is deployed via modules/ampls
# in each environment root, after both networking and loganalytics, to avoid
# a circular dependency (networking → loganalytics workspace ID → networking subnet ID).
