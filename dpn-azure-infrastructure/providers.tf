terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.56.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# Default provider for main subscription
provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
}

# Connectivity provider for accessing private DNS zones
provider "azurerm" {
  alias = "connectivity"
  features {}
  subscription_id                 = var.connectivity_subscription_id
  resource_provider_registrations = "none"
}
