# ==============================================================================
# DPN Infrastructure - Reference Deployment
# ==============================================================================
# This configuration deploys the complete DPN infrastructure including:
# - Networking (subnets and NSGs)
# - Log Analytics workspace for monitoring
# - Key Vault for secrets management
# - Azure Container Registry for container images
# - Azure Kubernetes Service for container orchestration
# ==============================================================================

# ------------------------------------------------------------------------------
# Networking
# ------------------------------------------------------------------------------
module "networking" {
  source = "../modules/networking"

  vnet_name                         = var.vnet_name
  vnet_resource_group_name          = var.vnet_resource_group_name
  location                          = var.location
  location_short                    = var.location_short
  project_name                      = var.project_name
  environment                       = var.environment
  instance_number                   = var.instance_number
  subnets                           = var.subnets
  enable_diagnostic_settings        = var.enable_diagnostic_settings
  log_analytics_workspace_name      = var.log_analytics_workspace_name
  log_analytics_resource_group_name = var.log_analytics_resource_group_name
  tags                              = var.tags
}

# ------------------------------------------------------------------------------
# Monitoring
# ------------------------------------------------------------------------------
module "loganalytics" {
  source = "../modules/loganalytics"

  log_analytics_workspace_name      = var.log_analytics_workspace_name
  log_analytics_resource_group_name = var.log_analytics_resource_group_name
  location                          = var.location
  sku                               = var.log_analytics_sku
  retention_in_days                 = var.log_analytics_retention_in_days
  identity_type                     = var.log_analytics_identity_type
  vnet_name                         = var.vnet_name
  vnet_resource_group_name          = var.vnet_resource_group_name
  connectivity_subscription_id      = var.connectivity_subscription_id
  private_dns_zone_resource_group   = var.private_dns_zone_resource_group
  tags                              = var.tags

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  depends_on = [module.networking]
}

# ------------------------------------------------------------------------------
# Security
# ------------------------------------------------------------------------------
module "keyvault" {
  source = "../modules/keyvault"

  keyvault_name                        = var.keyvault_name
  resource_group_name                  = var.keyvault_resource_group_name
  location                             = var.location
  keyvault_sku_name                    = var.keyvault_sku_name
  soft_delete_retention_days           = var.keyvault_soft_delete_retention_days
  purge_protection_enabled             = var.keyvault_purge_protection_enabled
  enabled_for_disk_encryption          = var.keyvault_enabled_for_disk_encryption
  enabled_for_deployment               = var.keyvault_enabled_for_deployment
  enabled_for_template_deployment      = var.keyvault_enabled_for_template_deployment
  network_acls_bypass                  = var.keyvault_network_acls_bypass
  network_acls_default_action          = var.keyvault_network_acls_default_action
  network_acls_enabled                 = var.keyvault_network_acls_enabled
  allowed_ip_ranges                    = var.keyvault_allowed_ip_ranges
  allowed_subnet_ids                   = var.keyvault_allowed_subnet_ids
  key_vault_admin_object_ids           = var.keyvault_admin_object_ids
  key_vault_secrets_officer_object_ids = var.keyvault_secrets_officer_object_ids
  key_vault_secrets_user_object_ids    = var.keyvault_secrets_user_object_ids
  initial_secrets                      = var.keyvault_initial_secrets
  initial_keys                         = var.keyvault_initial_keys
  initial_certificates                 = var.keyvault_initial_certificates
  rbac_authorization_enabled           = var.keyvault_rbac_authorization_enabled
  vnet_name                            = var.vnet_name
  vnet_resource_group_name             = var.vnet_resource_group_name
  log_analytics_workspace_name         = var.log_analytics_workspace_name
  log_analytics_resource_group_name    = var.log_analytics_resource_group_name
  connectivity_subscription_id         = var.connectivity_subscription_id
  private_dns_zone_resource_group      = var.private_dns_zone_resource_group
  public_network_access_enabled        = var.keyvault_public_network_access_enabled
  enable_diagnostic_settings           = var.enable_diagnostic_settings
  subnet_id                            = module.networking.subnet_ids["keyvault"]
  log_analytics_workspace_id           = module.loganalytics.log_analytics_workspace_id
  tags                                 = var.tags

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }
}

# ------------------------------------------------------------------------------
# Container Services
# ------------------------------------------------------------------------------
module "container_registry" {
  source = "../modules/container_registry"

  acr_name                          = var.acr_name
  resource_group_name               = var.acr_resource_group_name
  location                          = var.location
  sku                               = var.acr_sku
  admin_enabled                     = var.acr_admin_enabled
  anonymous_pull_enabled            = var.acr_anonymous_pull_enabled
  zone_redundancy_enabled           = var.acr_zone_redundancy_enabled
  network_rules_enabled             = var.acr_network_rules_enabled
  network_rule_default_action       = var.acr_network_rule_default_action
  allowed_ip_ranges                 = var.acr_allowed_ip_ranges
  retention_policy_enabled          = var.acr_retention_policy_enabled
  retention_policy_days             = var.acr_retention_policy_days
  trust_policy_enabled              = var.acr_trust_policy_enabled
  encryption_enabled                = var.acr_encryption_enabled
  key_vault_key_id                  = var.acr_encryption_enabled ? module.keyvault.key_ids["cmk-key"] : null
  key_vault_id                      = var.acr_encryption_enabled ? module.keyvault.keyvault_id : null
  create_scope_maps                 = var.acr_create_scope_maps
  webhooks                          = var.acr_webhooks
  georeplications                   = var.acr_georeplications
  vnet_name                         = var.vnet_name
  vnet_resource_group_name          = var.vnet_resource_group_name
  connectivity_subscription_id      = var.connectivity_subscription_id
  private_dns_zone_resource_group   = var.private_dns_zone_resource_group
  log_analytics_workspace_name      = var.log_analytics_workspace_name
  log_analytics_resource_group_name = var.log_analytics_resource_group_name
  public_network_access_enabled     = var.acr_public_network_access_enabled
  enable_diagnostic_settings        = var.enable_diagnostic_settings
  subnet_id                         = module.networking.subnet_ids["acr"]
  log_analytics_workspace_id        = module.loganalytics.log_analytics_workspace_id
  tags                              = var.tags

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }
}

# ========================================
# Wait for Key Vault RBAC Propagation
# ========================================
# Azure RBAC can take 10-60 seconds to propagate
# This prevents VM password secret creation from failing with 403 Forbidden
resource "time_sleep" "wait_for_keyvault_rbac" {
  depends_on = [module.keyvault]

  create_duration = "30s"
}

# ========================================
# AKS Module
# ========================================
module "aks" {
  source                                     = "../modules/aks"
  aks_name                                   = var.aks_name
  resource_group_name                        = var.aks_resource_group_name
  node_resource_group                        = var.aks_node_resource_group
  location                                   = var.location
  vnet_name                                  = var.vnet_name
  vnet_resource_group_name                   = var.vnet_resource_group_name
  vnet_subnet_name                           = var.aks_vnet_subnet_name
  kubernetes_version                         = var.aks_kubernetes_version
  private_dns_zone_id                        = var.aks_private_dns_zone_id
  aks_admin_group                            = var.aks_admin_group
  log_analytics_workspace_name               = var.log_analytics_workspace_name
  log_analytics_resource_group_name          = var.log_analytics_resource_group_name
  service_cidr                               = var.aks_service_cidr
  dns_service_ip                             = var.aks_dns_service_ip
  sku_tier                                   = var.aks_sku_tier
  vm_size                                    = var.aks_vm_size
  node_count                                 = var.aks_node_count
  enable_auto_scaling                        = var.aks_enable_auto_scaling
  min_count                                  = var.aks_min_count
  max_count                                  = var.aks_max_count
  automatic_upgrade_channel                  = var.aks_automatic_upgrade_channel
  node_os_upgrade_channel                    = var.aks_node_os_upgrade_channel
  private_cluster_enabled                    = var.aks_private_cluster_enabled
  enable_workload_node_pool                  = var.aks_enable_workload_node_pool
  workload_node_pool_vm_size                 = var.aks_workload_node_pool_vm_size
  workload_node_pool_count                   = var.aks_workload_node_pool_count
  workload_node_pool_taints                  = var.aks_workload_node_pool_taints
  service_mesh_mode                          = var.aks_service_mesh_mode
  service_mesh_revisions                     = var.aks_service_mesh_revisions
  identity_type                              = var.aks_identity_type
  http_application_routing_enabled           = var.aks_http_application_routing_enabled
  node_pool_zones                            = var.aks_node_pool_zones
  max_surge                                  = var.aks_max_surge
  drain_timeout_in_minutes                   = var.aks_drain_timeout_in_minutes
  node_soak_duration_in_minutes              = var.aks_node_soak_duration_in_minutes
  network_plugin                             = var.aks_network_plugin
  network_policy                             = var.aks_network_policy
  load_balancer_sku                          = var.aks_load_balancer_sku
  network_plugin_mode                        = var.aks_network_plugin_mode
  secret_rotation_enabled                    = var.aks_secret_rotation_enabled
  secret_rotation_interval                   = var.aks_secret_rotation_interval
  workload_node_pool_zones                   = var.aks_workload_node_pool_zones
  azure_policy_enabled                       = var.aks_azure_policy_enabled
  local_account_disabled                     = var.aks_local_account_disabled
  oidc_issuer_enabled                        = var.aks_oidc_issuer_enabled
  workload_identity_enabled                  = var.aks_workload_identity_enabled
  host_encryption_enabled                    = var.aks_host_encryption_enabled
  azure_rbac_enabled                         = var.aks_azure_rbac_enabled
  key_vault_id                               = module.keyvault.keyvault_id
  encryption_enabled                         = var.aks_encryption_enabled
  key_vault_key_id                           = var.aks_encryption_enabled ? module.keyvault.key_ids["cmk-key"] : null
  enable_diagnostic_settings                 = var.aks_enable_diagnostic_settings
  container_registry_id                      = module.container_registry.acr_id
  connectivity_subscription_id               = var.connectivity_subscription_id
  private_dns_zone_resource_group            = var.private_dns_zone_resource_group
  default_node_pool_name                     = var.aks_default_node_pool_name
  workload_node_pool_name                    = var.aks_workload_node_pool_name
  workload_node_pool_host_encryption_enabled = var.aks_workload_node_pool_host_encryption_enabled
  workload_node_pool_label_key               = var.aks_workload_node_pool_label_key
  workload_node_pool_label_value             = var.aks_workload_node_pool_label_value
  acr_pull_role_name                         = var.aks_acr_pull_role_name
  user_assigned_identity_type                = var.aks_user_assigned_identity_type
  diagnostic_all_metrics_category            = var.aks_diagnostic_all_metrics_category
  diagnostic_all_logs_category_group         = var.aks_diagnostic_all_logs_category_group
  external_acr_pull_principal_ids            = var.aks_external_acr_pull_principal_ids
  subnet_id                                  = module.networking.subnet_ids["aks"]
  vnet_id                                    = module.networking.vnet_id
  log_analytics_workspace_id                 = module.loganalytics.log_analytics_workspace_id
  tags                                       = var.tags

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }
}

# ========================================
# Developer Storage Account Module
# ========================================
module "dev_storage" {
  source = "../modules/storage"

  storage_account_name                      = var.dev_storage_account_name
  resource_group_name                       = var.dev_storage_resource_group_name
  location                                  = var.location
  account_tier                              = var.dev_storage_account_tier
  replication_type                          = var.dev_storage_replication_type
  account_kind                              = var.dev_storage_account_kind
  access_tier                               = var.dev_storage_access_tier
  public_network_access_enabled             = var.dev_storage_public_network_access_enabled
  min_tls_version                           = var.dev_storage_min_tls_version
  versioning_enabled                        = var.dev_storage_versioning_enabled
  blob_retention_days                       = var.dev_storage_blob_retention_days
  container_retention_days                  = var.dev_storage_container_retention_days
  dev_team_spn_object_id                    = var.dev_team_spn_object_id
  additional_blob_contributor_principal_ids = var.dev_storage_additional_blob_contributor_principal_ids
  create_blob_endpoint                      = var.dev_storage_create_blob_endpoint
  file_share_name                           = var.dev_storage_file_share_name
  file_share_quota_gb                       = var.dev_storage_file_share_quota_gb
  create_file_endpoint                      = var.dev_storage_create_file_endpoint
  encryption_enabled                        = var.dev_storage_encryption_enabled
  key_vault_key_id                          = var.dev_storage_encryption_enabled ? module.keyvault.key_ids["cmk-key"] : null
  key_vault_id                              = var.dev_storage_encryption_enabled ? module.keyvault.keyvault_id : null
  subnet_id                                 = module.networking.subnet_ids["devstorage"]
  private_dns_zone_resource_group           = var.private_dns_zone_resource_group
  connectivity_subscription_id              = var.connectivity_subscription_id
  enable_diagnostic_settings                = var.dev_storage_enable_diagnostic_settings
  log_analytics_workspace_id                = module.loganalytics.log_analytics_workspace_id
  tags                                      = var.tags

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  depends_on = [module.networking, module.loganalytics]
}

# ========================================
# Workload Identity Module (AKS to Key Vault)
# ========================================
module "workload_identity" {
  source = "../modules/workload_identity"

  identity_name           = var.workload_identity_name
  resource_group_name     = var.aks_resource_group_name
  location                = var.location
  oidc_issuer_url         = module.aks.aks_oidc_issuer_url
  namespace               = var.workload_identity_namespace
  service_account_name    = var.workload_identity_service_account_name
  key_vault_id            = module.keyvault.keyvault_id
  enable_key_vault_access = var.workload_identity_key_vault_access_enabled
  tags                    = var.tags

  depends_on = [module.aks, module.keyvault]
}

# ========================================
# Ratify Workload Identity - AKS image signature verification (Key Vault cert read)
# Namespace/service account match the ratify-project/ratify Helm chart's default
# ServiceAccount ("ratify" in "gatekeeper-system") - confirm against the actual
# deployed ServiceAccount before first apply.
# ========================================
module "ratify_identity" {
  source = "../modules/workload_identity"

  identity_name           = replace(var.workload_identity_name, "id-aks-workload-", "id-ratify-")
  resource_group_name     = var.aks_resource_group_name
  location                = var.location
  oidc_issuer_url         = module.aks.aks_oidc_issuer_url
  namespace               = "gatekeeper-system"
  service_account_name    = "ratify-admin"
  key_vault_id            = module.keyvault.keyvault_id
  enable_key_vault_access = true
  tags                    = var.tags

  depends_on = [module.aks, module.keyvault]
}

resource "azurerm_role_assignment" "ratify_acr_pull" {
  scope                            = module.container_registry.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = module.ratify_identity.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

# ========================================
# VM Admin Password (Key Vault)
# ========================================
data "azurerm_key_vault_secret" "vm_admin_password" {
  count        = var.vm_admin_password_secret_name != "" ? 1 : 0
  name         = var.vm_admin_password_secret_name
  key_vault_id = module.keyvault.keyvault_id

  depends_on = [time_sleep.wait_for_keyvault_rbac]
}

locals {
  vm_admin_password_value = var.vm_admin_password_secret_name != "" ? data.azurerm_key_vault_secret.vm_admin_password[0].value : var.vm_admin_password
}

# ------------------------------------------------------------------------------
# Windows Virtual Machine
# ------------------------------------------------------------------------------
module "windows_vm" {
  source = "../modules/vm"

  vm_name                              = var.vm_name
  resource_group_name                  = var.vm_resource_group_name
  location                             = var.location
  vm_size                              = var.vm_size
  computer_name                        = var.vm_computer_name
  admin_username                       = var.vm_admin_username
  admin_password                       = local.vm_admin_password_value
  subnet_id                            = module.networking.subnet_ids[var.vm_subnet_name]
  private_ip_allocation                = var.vm_private_ip_allocation
  private_ip_address                   = var.vm_private_ip_address
  create_nsg                           = var.vm_create_nsg
  os_disk_caching                      = var.vm_os_disk_caching
  os_disk_storage_account_type         = var.vm_os_disk_storage_account_type
  os_disk_size_gb                      = var.vm_os_disk_size_gb
  image_publisher                      = var.vm_image_publisher
  image_offer                          = var.vm_image_offer
  image_sku                            = var.vm_image_sku
  image_version                        = var.vm_image_version
  identity_type                        = var.vm_identity_type
  enable_boot_diagnostics              = var.vm_enable_boot_diagnostics
  boot_diagnostics_storage_account_uri = var.vm_boot_diagnostics_storage_account_uri
  patch_mode                           = var.vm_patch_mode
  patch_assessment_mode                = var.vm_patch_assessment_mode
  enable_automatic_updates             = var.vm_enable_automatic_updates
  encryption_at_host_enabled           = var.vm_encryption_at_host_enabled
  secure_boot_enabled                  = var.vm_secure_boot_enabled
  vtpm_enabled                         = var.vm_vtpm_enabled
  license_type                         = var.vm_license_type
  timezone                             = var.vm_timezone
  availability_zone                    = var.vm_availability_zone
  enable_diagnostic_settings           = var.vm_enable_diagnostic_settings
  log_analytics_workspace_id           = var.vm_enable_diagnostic_settings ? module.loganalytics.log_analytics_workspace_id : null
  key_vault_id                         = module.keyvault.keyvault_id
  encryption_enabled                   = var.vm_encryption_enabled
  key_vault_key_id                     = var.vm_encryption_enabled ? module.keyvault.key_ids["cmk-key"] : null
  tags                                 = var.tags

  depends_on = [module.networking, module.loganalytics, module.keyvault, time_sleep.wait_for_keyvault_rbac]
}

# ========================================
# Azure Bastion (optional admin access path)
# ========================================
# RDP path into the jump host VM. This is one of two supported ways to reach
# this environment for day-to-day admin work - the other is an existing AVD
# (Azure Virtual Desktop) desktop with private network line of sight, which
# needs no module here at all. Which one you use is a per-customer decision:
# set bastion_enabled = true only if you don't already have an AVD-equivalent
# path into this VNet.
module "bastion" {
  count  = var.bastion_enabled ? 1 : 0
  source = "../modules/bastion"

  resource_group_name = var.bastion_resource_group_name
  location            = var.location
  bastion_host_name   = var.bastion_host_name
  public_ip_name      = var.bastion_public_ip_name

  virtual_network_id = module.networking.vnet_id

  sku                = var.bastion_sku
  scale_units        = var.bastion_scale_units
  copy_paste_enabled = var.bastion_copy_paste_enabled
  file_copy_enabled  = var.bastion_file_copy_enabled
  tunneling_enabled  = var.bastion_tunneling_enabled
  zones              = var.bastion_zones

  enable_diagnostic_settings = var.bastion_enable_diagnostic_settings
  log_analytics_workspace_id = module.loganalytics.log_analytics_workspace_id
  tags                       = var.tags
}

# ========================================
# Event Grid Module
# ========================================
module "event_grid" {
  source = "../modules/event_grid"

  topic_name                    = var.event_grid_topic_name
  resource_group_name           = var.event_grid_resource_group_name
  location                      = var.location
  local_auth_enabled            = var.event_grid_local_auth_enabled
  public_network_access_enabled = var.event_grid_public_network_access_enabled
  subnet_id                     = module.networking.subnet_ids[var.event_grid_subnet_name]
  data_receiver_principal_ids   = var.event_grid_data_receiver_principal_ids
  data_sender_principal_ids     = var.event_grid_data_sender_principal_ids
  contributor_principal_ids     = var.event_grid_contributor_principal_ids
  enable_diagnostic_settings    = var.event_grid_enable_diagnostic_settings
  log_analytics_workspace_id    = module.loganalytics.log_analytics_workspace_id
  tags                          = var.tags

  depends_on = [module.networking, module.loganalytics]
}

# ========================================
# Service Bus Module
# ========================================
module "service_bus" {
  source = "../modules/service_bus"

  namespace_name                = var.service_bus_namespace_name
  resource_group_name           = var.service_bus_resource_group_name
  location                      = var.location
  sku                           = var.service_bus_sku
  capacity                      = var.service_bus_capacity
  premium_messaging_partitions  = var.service_bus_premium_messaging_partitions
  public_network_access_enabled = var.service_bus_public_network_access_enabled
  minimum_tls_version           = var.service_bus_minimum_tls_version
  local_auth_enabled            = var.service_bus_local_auth_enabled
  trusted_services_allowed      = var.service_bus_trusted_services_allowed
  subnet_id                     = module.networking.subnet_ids[var.service_bus_subnet_name]
  queues                        = var.service_bus_queues
  data_receiver_principal_ids   = var.service_bus_data_receiver_principal_ids
  data_sender_principal_ids     = var.service_bus_data_sender_principal_ids
  data_owner_principal_ids      = var.service_bus_data_owner_principal_ids
  enable_diagnostic_settings    = var.service_bus_enable_diagnostic_settings
  log_analytics_workspace_id    = module.loganalytics.log_analytics_workspace_id
  encryption_enabled            = var.service_bus_encryption_enabled
  key_vault_key_id              = var.service_bus_encryption_enabled ? module.keyvault.key_ids["cmk-key"] : null
  key_vault_id                  = var.service_bus_encryption_enabled ? module.keyvault.keyvault_id : null
  tags                          = var.tags

  depends_on = [module.networking, module.loganalytics]
}

# ========================================
# Messaging Storage Account Module
# ========================================
module "file_scanning_service_storage" {
  source = "../modules/storage"

  storage_account_name            = var.file_scanning_service_storage_account_name
  resource_group_name             = var.file_scanning_service_storage_resource_group_name
  location                        = var.location
  account_tier                    = var.file_scanning_service_storage_account_tier
  replication_type                = var.file_scanning_service_storage_replication_type
  account_kind                    = var.file_scanning_service_storage_account_kind
  access_tier                     = var.file_scanning_service_storage_access_tier
  public_network_access_enabled   = var.file_scanning_service_storage_public_network_access_enabled
  min_tls_version                 = var.file_scanning_service_storage_min_tls_version
  versioning_enabled              = var.file_scanning_service_storage_versioning_enabled
  blob_retention_days             = var.file_scanning_service_storage_blob_retention_days
  container_retention_days        = var.file_scanning_service_storage_container_retention_days
  dev_team_spn_object_id          = var.file_scanning_service_storage_dev_team_spn_object_id
  create_blob_endpoint            = var.file_scanning_service_storage_create_blob_endpoint
  file_share_name                 = var.file_scanning_service_storage_file_share_name
  file_share_quota_gb             = var.file_scanning_service_storage_file_share_quota_gb
  create_file_endpoint            = var.file_scanning_service_storage_create_file_endpoint
  encryption_enabled              = var.file_scanning_service_storage_encryption_enabled
  key_vault_key_id                = var.file_scanning_service_storage_encryption_enabled ? module.keyvault.key_ids["cmk-key"] : null
  key_vault_id                    = var.file_scanning_service_storage_encryption_enabled ? module.keyvault.keyvault_id : null
  subnet_id                       = module.networking.subnet_ids[var.file_scanning_service_storage_subnet_name]
  private_dns_zone_resource_group = var.private_dns_zone_resource_group
  connectivity_subscription_id    = var.connectivity_subscription_id
  enable_diagnostic_settings      = var.file_scanning_service_storage_enable_diagnostic_settings
  log_analytics_workspace_id      = module.loganalytics.log_analytics_workspace_id
  tags                            = var.tags

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  depends_on = [module.networking, module.loganalytics]
}

resource "azurerm_role_assignment" "file_scanning_service_storage_data_reader" {
  for_each             = toset(var.file_scanning_service_storage_data_receiver_principal_ids)
  scope                = module.file_scanning_service_storage.storage_account_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "file_scanning_service_storage_data_contributor" {
  for_each             = toset(var.file_scanning_service_storage_data_contributor_principal_ids)
  scope                = module.file_scanning_service_storage.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

# ========================================
# Observability Logging Storage Module
# ========================================
module "observability_logging_storage" {
  source = "../modules/storage"

  storage_account_name            = var.observability_logging_storage_account_name
  resource_group_name             = var.observability_logging_storage_resource_group_name
  location                        = var.location
  account_tier                    = var.observability_logging_storage_account_tier
  replication_type                = var.observability_logging_storage_replication_type
  account_kind                    = var.observability_logging_storage_account_kind
  access_tier                     = var.observability_logging_storage_access_tier
  public_network_access_enabled   = var.observability_logging_storage_public_network_access_enabled
  min_tls_version                 = var.observability_logging_storage_min_tls_version
  versioning_enabled              = var.observability_logging_storage_versioning_enabled
  blob_retention_days             = var.observability_logging_storage_blob_retention_days
  container_retention_days        = var.observability_logging_storage_container_retention_days
  dev_team_spn_object_id          = var.observability_logging_storage_dev_team_spn_object_id
  create_blob_endpoint            = var.observability_logging_storage_create_blob_endpoint
  file_share_name                 = var.observability_logging_storage_file_share_name
  file_share_quota_gb             = var.observability_logging_storage_file_share_quota_gb
  create_file_endpoint            = var.observability_logging_storage_create_file_endpoint
  encryption_enabled              = var.observability_logging_storage_encryption_enabled
  key_vault_key_id                = var.observability_logging_storage_encryption_enabled ? module.keyvault.key_ids["cmk-key"] : null
  key_vault_id                    = var.observability_logging_storage_encryption_enabled ? module.keyvault.keyvault_id : null
  subnet_id                       = module.networking.subnet_ids[var.observability_logging_storage_subnet_name]
  private_dns_zone_resource_group = var.private_dns_zone_resource_group
  connectivity_subscription_id    = var.connectivity_subscription_id
  enable_diagnostic_settings      = var.observability_logging_storage_enable_diagnostic_settings
  log_analytics_workspace_id      = module.loganalytics.log_analytics_workspace_id
  tags                            = var.tags

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  depends_on = [module.networking, module.loganalytics]
}

resource "azurerm_role_assignment" "observability_logging_storage_data_reader" {
  for_each             = toset(var.observability_logging_storage_data_receiver_principal_ids)
  scope                = module.observability_logging_storage.storage_account_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "observability_logging_storage_data_contributor" {
  for_each             = toset(var.observability_logging_storage_data_contributor_principal_ids)
  scope                = module.observability_logging_storage.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}
