# Windows Virtual Machine Module

## Purpose in this architecture

This is the jump host referenced in `modules/bastion`'s README - the one VM in this deployment a human actually logs into, reached only through Azure Bastion (never a public IP). From here, a platform engineer has network line-of-sight to run `kubectl`/`az`/etc. against every other private-endpoint-only resource in the deployment. It is not meant to run application workloads - that's what `aks` is for.

`allow_extension_operations` defaults to `false` since nothing in this module installs a VM extension by default; flip it to `true` only if you need one (e.g. `AADLoginForWindows` for Azure AD-based RDP login, or the Azure Monitor Agent extension) - leaving it `false` reduces attack surface when you don't.

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

  vm_name             = "vm-app-dev-uks-01"
  resource_group_name = "rg-vm-dev-uks-01"
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

## Customer-Managed Key (CMK) Encryption

Set `encryption_enabled = true` plus `key_vault_key_id` (and the existing
`key_vault_id`) to encrypt the OS disk with your own Key Vault key via a
disk encryption set, instead of a Microsoft-managed key. The module creates
the disk encryption set and grants its identity `Key Vault Crypto Service
Encryption User` on `key_vault_id`.

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
| allow_extension_operations | Allow VM extensions to be installed | bool | false | no |
| subnet_id | ID of the subnet | string | - | yes |
| encryption_at_host_enabled | Enable encryption at host | bool | true | no |
| secure_boot_enabled | Enable secure boot | bool | true | no |
| vtpm_enabled | Enable vTPM | bool | true | no |
| reader_principal_ids | Object IDs granted Reader on the VM and its NIC (required by Azure Bastion to select this VM in the connect flow) | list(string) | [] | no |

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
