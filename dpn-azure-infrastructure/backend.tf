terraform {
  backend "azurerm" {}
}

# For local development, using local state
# The Azure DevOps pipeline will use remote state in azurerm backend
# backend "azurerm" {
#   resource_group_name  = "rg-terraform-state-uks-01"
#   storage_account_name = "sttfdpndevuks01"
#   container_name       = "tfstate"
#   key                  = "dpn.dev.tfstate"
#   use_azuread_auth     = true  # Use managed identity or Azure AD for authentication
# }

# NOTE: Azure Policy requires publicNetworkAccess='Disabled' for the storage account.
# To use this remote backend, you must run OpenTofu from:
# - An Azure VM or container in the same VNet
# - Azure DevOps pipeline with self-hosted agent in the VNet
# - GitHub Actions with self-hosted runner in the VNet
#
# For local development, comment out the backend block above to use local state.
