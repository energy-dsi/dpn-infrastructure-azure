# Azure Bastion Module

## Purpose in this architecture

Every other resource in this deployment (AKS API server, Key Vault, storage, ACR, etc.) is private-endpoint-only - there's no public entry point for a human to manage them directly. This module, together with `modules/vm`, is that entry point: a platform engineer connects to Azure Bastion in the Portal/CLI, which tunnels an RDP session to the Windows jump host VM, and from that VM (which sits inside the same VNet) they have network line-of-sight to run `kubectl`, `az`, or anything else against the private resources. Without this pair of modules, day-to-day operation of a fully-private deployment like this one would have no admin access path at all.

This module deploys Azure Bastion as the RDP access path onto the jump host VM. It supports two distinct deployment shapes depending on `sku`:

- **Developer SKU** — attaches directly to the VNet via `virtual_network_id`. No dedicated `AzureBastionSubnet`, no NSG, no public IP at all. Single concurrent session, no scaling, no native-client tunneling.
- **Basic/Standard/Premium** — the traditional shape: a dedicated `AzureBastionSubnet` (exact name, `/26` minimum) with its own NSG and a public IP.

## Choosing a SKU

Azure Bastion's `AllowHttpsInbound` NSG rule (required for Basic/Standard/Premium) needs `source_address_prefix = "Internet"` — a hard platform requirement for the public-IP shape, not something that can be reconfigured around. If your tenant enforces a policy that denies broad `Internet`-sourced NSG rules (a common landing-zone guardrail), Basic/Standard/Premium will be blocked by that policy. Developer SKU sidesteps the conflict entirely: it doesn't create `AzureBastionSubnet`, doesn't create an NSG, and doesn't need a public IP, so there's no NSG rule for any policy to evaluate.

Developer SKU is the right default for a single, per-environment deployment with no policy exemption required. If your organization already runs a centralized hub Bastion (Standard/Premium, in a dedicated Bastion hub VNet), routing through that via VNet peering instead of deploying a per-environment instance is a valid alternative - it just requires that peering to exist.

**Tradeoff to keep in mind**: Developer SKU supports exactly one concurrent session. If multiple app-team members need simultaneous access, this will bottleneck — worth revisiting if that becomes a real constraint.

## Features

- **`azurerm_bastion_host`** — Developer SKU by default; `virtual_network_id` used instead of `subnet_id`/`ip_configuration`
- **`azurerm_public_ip`** — only created for Basic/Standard/Premium (`count = var.sku == "Developer" ? 0 : 1`); Developer SKU has none
- **Diagnostic settings** — all Bastion audit logs and metrics streamed to Log Analytics (works regardless of SKU)

## Usage (Developer SKU)

```hcl
module "bastion" {
  source = "../modules/bastion"

  resource_group_name = var.bastion_resource_group_name
  location             = var.location
  bastion_host_name    = var.bastion_host_name
  public_ip_name       = var.bastion_public_ip_name

  virtual_network_id = module.networking.vnet_id

  sku = var.bastion_sku # "Developer"

  enable_diagnostic_settings = var.bastion_enable_diagnostic_settings
  log_analytics_workspace_id = module.loganalytics.log_analytics_workspace_id

  tags = var.tags
}
```

## Usage (Standard/Premium, dedicated AzureBastionSubnet)

```hcl
module "bastion" {
  source = "../modules/bastion"

  resource_group_name = var.bastion_resource_group_name
  location             = var.location
  bastion_host_name    = var.bastion_host_name
  public_ip_name       = var.bastion_public_ip_name

  subnet_id = module.networking.subnet_ids["AzureBastionSubnet"]

  sku                = var.bastion_sku
  scale_units        = var.bastion_scale_units
  tunneling_enabled  = var.bastion_tunneling_enabled
  file_copy_enabled  = var.bastion_file_copy_enabled
  copy_paste_enabled = var.bastion_copy_paste_enabled

  enable_diagnostic_settings = var.bastion_enable_diagnostic_settings
  log_analytics_workspace_id = module.loganalytics.log_analytics_workspace_id

  tags = var.tags
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `resource_group_name` | Dedicated resource group for the Bastion host (and its public IP, if any) | `string` | - | yes |
| `location` | Azure region | `string` | - | yes |
| `bastion_host_name` | Name of the Azure Bastion host | `string` | - | yes |
| `public_ip_name` | Name of the Bastion host's public IP | `string` | `null` | conditional (Basic/Standard/Premium only) |
| `subnet_id` | ID of the `AzureBastionSubnet` (exact name required by Azure, minimum `/26`). Required for Basic/Standard/Premium; not used for Developer. | `string` | `null` | conditional |
| `virtual_network_id` | ID of the VNet to attach a Developer SKU host to. Required (and only valid) when `sku = "Developer"`. | `string` | `null` | conditional |
| `sku` | `Developer`, `Basic`, `Standard`, or `Premium` | `string` | `Standard` | no |
| `scale_units` | Scale units, 2-50 (Standard/Premium only) | `number` | `2` | no |
| `copy_paste_enabled` | Enable copy/paste in sessions | `bool` | `true` | no |
| `file_copy_enabled` | Enable file copy (Standard/Premium only) | `bool` | `true` | no |
| `tunneling_enabled` | Enable native client support — `az network bastion tunnel/rdp/ssh` (Standard/Premium only) | `bool` | `true` | no |
| `ip_connect_enabled` | Enable IP-based connection (Premium only) | `bool` | `false` | no |
| `shareable_link_enabled` | Enable shareable link (Standard/Premium only) | `bool` | `false` | no |
| `kerberos_enabled` | Enable Kerberos authentication | `bool` | `false` | no |
| `zones` | Availability zones (Standard/Premium only) | `list(string)` | `[]` | no |
| `enable_diagnostic_settings` | Stream Bastion audit logs/metrics to Log Analytics | `bool` | `true` | no |
| `log_analytics_workspace_id` | Log Analytics workspace ID | `string` | `null` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

- `bastion_id` — ID of the Azure Bastion host
- `bastion_name` — Name of the Azure Bastion host
- `bastion_public_ip` — Public IP address of the Bastion host (`null` for Developer SKU)
- `resource_group_name` — Name of the resource group created for the Bastion host

## Important Notes

- **RBAC needed to actually connect**: a user needs `Reader` on the Bastion resource, `Reader` (or better) on the target VM, and `Virtual Machine User Login`/`Virtual Machine Administrator Login` (or the local Windows credentials) — Bastion tunnels the RDP session, it does not itself authenticate the user into Windows.
- **Getting from the VM to AKS is a separate concern**: once RDP'd into the jump host, running `kubectl` against the AKS cluster requires (a) network reachability from the VM's subnet to the AKS private API server — the VM is on the same VNet so this should work; (b) `az`/`kubectl`/`kubelogin` installed on the VM (not pre-installed on a stock Windows Server image); (c) the connecting identity having both `Azure Kubernetes Service Cluster User Role` (to fetch a kubeconfig) **and**, since these clusters run with `azure_rbac_enabled = true`, a Kubernetes-data-plane role — already wired via `aks_admin_group` granting `Azure Kubernetes Service RBAC Writer` (see `modules/aks`).
- **If Basic/Standard/Premium is ever needed instead** (e.g. multiple concurrent sessions become a real requirement), that path requires either a policy exemption for the `AzureBastionSubnet` NSG's `AllowHttpsInbound` rule, or routing through a centralized hub Bastion via VNet peering instead of a per-environment deployment.
