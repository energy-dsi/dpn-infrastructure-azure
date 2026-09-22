# ==============================================================================
# AKS Cluster
# ==============================================================================
# Creates an Azure Kubernetes Service cluster with:
# - Private cluster configuration
# - Istio service mesh
# - Azure RBAC integration
# - Log Analytics monitoring
# - Key Vault secrets provider
# ==============================================================================

terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.connectivity]
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# ------------------------------------------------------------------------------
# Resource Group
# ------------------------------------------------------------------------------
resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# ------------------------------------------------------------------------------
# User Assigned Managed Identity for AKS
# ------------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${var.aks_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.aks.name
  tags                = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# Grant Private DNS Zone Contributor on the centralized DNS zone
resource "azurerm_role_assignment" "aks_dns_contributor" {
  provider             = azurerm.connectivity
  scope                = var.private_dns_zone_id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Grant Network Contributor on VNet for DNS zone virtual network link
resource "azurerm_role_assignment" "aks_identity_vnet_contributor" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Grant Network Contributor on AKS subnet for the User Assigned Identity
resource "azurerm_role_assignment" "aks_identity_network_contributor" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Wait for RBAC propagation before creating AKS cluster
resource "time_sleep" "wait_for_rbac_propagation" {
  depends_on = [
    azurerm_role_assignment.aks_dns_contributor,
    azurerm_role_assignment.aks_identity_vnet_contributor,
    azurerm_role_assignment.aks_identity_network_contributor
  ]

  create_duration = "60s"
}

# ------------------------------------------------------------------------------
# Customer-managed key support: node OS disks (via Disk Encryption Set) and
# etcd / Kubernetes Secrets (via the key_management_service block below).
# ------------------------------------------------------------------------------
resource "azurerm_disk_encryption_set" "aks" {
  count               = var.encryption_enabled ? 1 : 0
  name                = "${var.aks_name}-des"
  resource_group_name = azurerm_resource_group.aks.name
  location            = var.location
  key_vault_key_id    = var.key_vault_key_id
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# Grants the disk encryption set's identity permission to wrap/unwrap the CMK
# used for node OS disks.
resource "azurerm_role_assignment" "aks_des_cmk" {
  count                = var.encryption_enabled ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_disk_encryption_set.aks[0].identity[0].principal_id
}

# Grants the AKS cluster identity permission to wrap/unwrap the CMK used for
# etcd / Kubernetes Secrets encryption (key_management_service block below).
resource "azurerm_role_assignment" "aks_cluster_identity_cmk" {
  count                = var.encryption_enabled ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# ------------------------------------------------------------------------------
# AKS Cluster
# ------------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = var.location
  resource_group_name = azurerm_resource_group.aks.name
  node_resource_group = var.node_resource_group
  kubernetes_version  = var.kubernetes_version
  # Use dns_prefix_private_cluster for private cluster with custom DNS zone
  dns_prefix_private_cluster = var.private_cluster_enabled ? var.aks_name : null
  # dns_prefix not used for private clusters
  dns_prefix              = null
  private_cluster_enabled = var.private_cluster_enabled
  # Use the provided private DNS zone ID directly to avoid replacement issues
  private_dns_zone_id       = var.private_dns_zone_id
  sku_tier                  = var.sku_tier
  automatic_upgrade_channel = var.automatic_upgrade_channel
  node_os_upgrade_channel   = var.node_os_upgrade_channel
  # Customer-managed key for node OS disks (ForceNew - set at cluster creation only)
  disk_encryption_set_id = var.encryption_enabled ? azurerm_disk_encryption_set.aks[0].id : null

  # Enable Istio service mesh
  service_mesh_profile {
    mode      = var.service_mesh_mode
    revisions = var.service_mesh_revisions
  }

  # Use user-assigned managed identity (required for custom private DNS zone)
  identity {
    type         = var.user_assigned_identity_type
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Security and compliance features
  azure_policy_enabled             = var.azure_policy_enabled
  http_application_routing_enabled = var.http_application_routing_enabled
  local_account_disabled           = var.local_account_disabled
  oidc_issuer_enabled              = var.oidc_issuer_enabled
  workload_identity_enabled        = var.workload_identity_enabled

  # Default node pool configuration
  default_node_pool {
    name                        = var.default_node_pool_name
    vm_size                     = var.vm_size
    vnet_subnet_id              = var.subnet_id
    host_encryption_enabled     = var.host_encryption_enabled
    node_count                  = var.enable_auto_scaling ? null : var.node_count
    auto_scaling_enabled        = var.enable_auto_scaling
    min_count                   = var.enable_auto_scaling ? var.min_count : null
    max_count                   = var.enable_auto_scaling ? var.max_count : null
    zones                       = var.node_pool_zones
    temporary_name_for_rotation = "systemp"

    upgrade_settings {
      max_surge                     = var.max_surge
      drain_timeout_in_minutes      = var.drain_timeout_in_minutes
      node_soak_duration_in_minutes = var.node_soak_duration_in_minutes
    }
  }

  # Customer-managed key for etcd / Kubernetes Secrets encryption
  dynamic "key_management_service" {
    for_each = var.encryption_enabled ? [1] : []
    content {
      key_vault_key_id         = var.key_vault_key_id
      key_vault_network_access = var.key_vault_network_access
    }
  }

  # Azure AD RBAC configuration
  azure_active_directory_role_based_access_control {
    admin_group_object_ids = var.aks_admin_group
    azure_rbac_enabled     = var.azure_rbac_enabled
  }

  # Network configuration
  network_profile {
    network_plugin      = var.network_plugin
    network_policy      = var.network_policy
    load_balancer_sku   = var.load_balancer_sku
    network_plugin_mode = var.network_plugin == "azure" ? var.network_plugin_mode : null
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  # Monitoring integration
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # Key Vault secrets provider
  key_vault_secrets_provider {
    secret_rotation_enabled  = var.secret_rotation_enabled
    secret_rotation_interval = var.secret_rotation_interval
  }

  tags = var.tags

  depends_on = [
    time_sleep.wait_for_rbac_propagation,
    azurerm_role_assignment.aks_des_cmk,
    azurerm_role_assignment.aks_cluster_identity_cmk,
  ]

  lifecycle {
    # Prevent accidental cluster destruction
    # This will cause Terraform to error instead of destroying the cluster
    # To destroy, this must be manually removed or overridden
    prevent_destroy = true

    # Ignore changes to properties that shouldn't trigger replacement
    ignore_changes = [
      # Node count is managed by autoscaling
      default_node_pool[0].node_count,
      # Kubernetes version upgrades should be done via upgrade channels, not Terraform
      kubernetes_version,
      # Tags may be modified outside Terraform
      tags
    ]
  }
}

# ------------------------------------------------------------------------------
# Diagnostic Settings
# ------------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "aks_diagnostic" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.aks_name}-diagnostic"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_metric {
    category = var.diagnostic_all_metrics_category
  }

  enabled_log {
    category_group = var.diagnostic_all_logs_category_group
  }
}

# ------------------------------------------------------------------------------
# Additional Node Pool (Workloads)
# ------------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  count                       = var.enable_workload_node_pool ? 1 : 0
  name                        = var.workload_node_pool_name
  kubernetes_cluster_id       = azurerm_kubernetes_cluster.aks.id
  vm_size                     = var.workload_node_pool_vm_size
  node_count                  = var.workload_node_pool_count
  vnet_subnet_id              = var.subnet_id
  zones                       = var.workload_node_pool_zones
  host_encryption_enabled     = var.workload_node_pool_host_encryption_enabled
  temporary_name_for_rotation = "worktemp"

  node_labels = {
    (var.workload_node_pool_label_key) = var.workload_node_pool_label_value
  }

  node_taints = var.workload_node_pool_taints

  upgrade_settings {
    max_surge                     = var.max_surge
    drain_timeout_in_minutes      = var.drain_timeout_in_minutes
    node_soak_duration_in_minutes = var.node_soak_duration_in_minutes
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# ------------------------------------------------------------------------------
# RBAC Assignments
# ------------------------------------------------------------------------------

# Allow AKS kubelet identity to pull images from ACR
resource "azurerm_role_assignment" "kubelet_acr_pull" {
  scope                = var.container_registry_id
  role_definition_name = var.acr_pull_role_name
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Allow AKS Key Vault secrets provider to read secrets
resource "azurerm_role_assignment" "aks_keyvault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Azure Kubernetes Service Cluster User Role for admin group
resource "azurerm_role_assignment" "aks_cluster_user" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = var.aks_admin_group[0]

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# ACR Pull role for admin group
resource "azurerm_role_assignment" "admin_group_acr_pull" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_admin_group[0]
}

# ACR Push role for admin group
resource "azurerm_role_assignment" "admin_group_acr_push" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPush"
  principal_id         = var.aks_admin_group[0]
}

# AcrPull for external identities (e.g. another cluster's managed identity pulling from this ACR)
resource "azurerm_role_assignment" "external_acr_pull" {
  for_each             = toset(var.external_acr_pull_principal_ids)
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = each.value
}
