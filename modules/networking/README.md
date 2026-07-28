# Networking Module

## Purpose in this architecture

This is the shared backbone every other module in this repo depends on: it carves the subnets out of your **existing** VNet (this module does not create the VNet itself - that's assumed to be shared platform infrastructure you don't own) that every private endpoint - AKS, Key Vault, ACR, storage, Event Grid, Service Bus - lands in. `dpn-azure-infrastructure/main.tf` calls this module once, with every subnet the whole deployment needs declared in the `subnets` map, and every other module then references `module.networking.subnet_ids["..."]`.

Subnets are created via `null_resource` + `local-exec` (Azure CLI) rather than a plain `azurerm_subnet` resource, so that the subnet and its NSG can be attached atomically at creation time - a workaround for tenants whose Azure Policy requires an NSG to already be attached the moment a subnet is created, which a two-step "create subnet, then associate NSG" apply can't satisfy.

This module creates subnets in an existing Azure Virtual Network with optional Network Security Groups (NSGs) and diagnostic settings.

## Features

- Creates multiple subnets in an existing VNet
- Optional subnet delegation for Azure services
- Optional NSG creation and association per subnet
- Configurable NSG rules
- Diagnostic settings integration with Log Analytics
- Support for private endpoint network policies

## Usage

```hcl
module "networking" {
  source = "./networking"
  
  vnet_name                = "vnet-app-dev-uks-01"
  vnet_resource_group_name = "rg-network-dev-uks-01"
  location                 = "UK South"
  
  subnets = {
    aks = {
      address_prefix = "10.0.4.0/27"
    }
    keyvault = {
      address_prefix = "10.0.4.32/29"
      create_nsg     = true
      nsg_name       = "nsg-keyvault"
    }
  }
  
  enable_diagnostic_settings        = true
  log_analytics_workspace_name      = "log-app-dev-uks-01"
  log_analytics_resource_group_name = "rg-monitoring-dev-uks-01"
  
  tags = {
    Environment = "Development"
    ManagedBy   = "OpenTofu"
  }
}
```

## Subnet Configuration

### Basic Subnet
```hcl
webapp = {
  address_prefix = "10.0.1.0/24"
}
```

### Subnet with Delegation
```hcl
mysql = {
  address_prefix = "10.0.2.0/24"
  delegation = {
    name                       = "mysql-delegation"
    service_delegation_name    = "Microsoft.DBforMySQL/flexibleServers"
    service_delegation_actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  }
}
```

### Subnet with NSG
```hcl
app = {
  address_prefix = "10.0.3.0/24"
  create_nsg     = true
  nsg_name       = "nsg-app"
  nsg_rules = {
    allow_https = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
  }
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| vnet_name | Name of the existing VNet | string | yes |
| vnet_resource_group_name | Resource group of the VNet | string | yes |
| location | Azure region | string | yes |
| subnets | Map of subnet configurations | map(object) | yes |
| tags | Tags to apply to resources | map(string) | no |
| enable_diagnostic_settings | Enable diagnostics for NSGs | bool | no |
| log_analytics_workspace_name | Log Analytics workspace name | string | no |
| log_analytics_resource_group_name | Log Analytics RG name | string | no |

## Outputs

| Name | Description |
|------|-------------|
| subnet_ids | Map of subnet names to IDs |
| subnet_address_prefixes | Map of subnet names to address prefixes |
| nsg_ids | Map of NSG names to IDs |
| vnet_id | Virtual network ID |
| vnet_name | Virtual network name |
| vnet_address_space | Virtual network address space |

## Requirements

- Existing Azure Virtual Network
- Azure provider v4.8.0 or later
- If enabling diagnostics, Log Analytics workspace must exist

## Notes

- Subnets are created in the existing VNet
- NSGs are optional per subnet
- Private endpoint network policies are disabled by default
- Default outbound access is enabled by default
