# Windows Virtual Machine Module

## Purpose in this architecture

The Windows jump host that Azure Bastion (`modules/bastion`) RDPs into when `bastion_enabled = true`, or that you reach some other way (e.g. an existing AVD desktop) otherwise - see the root README's admin-access section. This module is always deployed regardless of `bastion_enabled`, since it's also useful standalone for Windows-based management or legacy workloads.

This OpenTofu module creates a Windows Virtual Machine in Azure with security best practices.

## Features

- **Windows Server 2022** (Azure Edition)
- **AMD64 architecture** support
- **Managed identity** (SystemAssigned by default)
- **Encryption at host** enabled
- **Secure Boot** and **vTPM** enabled (Gen2 VMs)
- **Automatic patching** via Azure Update Manager
- **Boot diagnostics** with managed storage
- **Network Security Group** (optional)
- **Diagnostic settings** for Log Analytics integration

## Usage

```hcl
module "windows_vm" {
  source = "./modules/vm"

  vm_name             = "vm-dpn-azure-uks-01"
  resource_group_name = "rg-vm-dpn-azure-uks-01"
  location            = "UK South"
  vm_size             = "Standard_D2s_v5"
  
  admin_username = "adminuser"
  admin_password = "<secure-password-from-key-vault>"
  
  subnet_id = azurerm_subnet.vm.id
  
  # Security features
  encryption_at_host_enabled = true
  secure_boot_enabled        = true
  vtpm_enabled               = true
  
  # Diagnostics
  enable_diagnostic_settings  = true
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.main.id
  
  tags = {
    Environment = "Development"
    ManagedBy   = "OpenTofu"
  }
}
```

## Security Recommendations

1. **Store admin password in Key Vault** - Never hardcode passwords
2. **Use Azure Bastion** - For secure remote access without public IPs
3. **Enable Update Management** - Automatic patching enabled by default
4. **Use Network Security Groups** - Restrict network access
5. **Enable diagnostic logging** - Send logs to Log Analytics

## Image Details

- **Publisher**: MicrosoftWindowsServer
- **Offer**: WindowsServer
- **SKU**: 2022-datacenter-azure-edition
- **Version**: latest

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vm_name | Name of the virtual machine | string | - | yes |
| resource_group_name | Name of the resource group | string | - | yes |
| location | Azure region | string | - | yes |
| vm_size | VM size (e.g., Standard_D2s_v5) | string | - | yes |
| admin_username | Administrator username | string | - | yes |
| admin_password | Administrator password | string | - | yes |
| subnet_id | ID of the subnet | string | - | yes |
| encryption_at_host_enabled | Enable encryption at host | bool | true | no |
| secure_boot_enabled | Enable secure boot | bool | true | no |
| vtpm_enabled | Enable vTPM | bool | true | no |

## Outputs

| Name | Description |
|------|-------------|
| vm_id | ID of the virtual machine |
| vm_name | Name of the virtual machine |
| private_ip_address | Private IP address |
| network_interface_id | ID of the network interface |
| identity_principal_id | Principal ID of managed identity |

## Requirements

- OpenTofu >= 1.6
- Azure Provider >= 3.0
- **Subscription must have encryption at host quota** (enable via Azure support ticket if needed)
