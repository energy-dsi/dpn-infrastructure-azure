# ========================================
# DPN Environment Configuration (Example)
# ========================================
# Edit this file directly and replace every placeholder value (subscription
# IDs, object IDs, resource names, CIDR ranges) with your own - the deploy
# and destroy pipelines reference this exact file
# (environments/dpn_infrastructure.tfvars) as their -var-file.
# Naming Convention: <type>-dpn-azure-<region>-<instance>
# Subscription: <your-subscription-name> (<your-subscription-id>)
# VNet CIDR: 10.0.1.0/24
# ========================================

subscription_id = "00000000-0000-0000-0000-000000000000"

# ========================================
# Networking
# ========================================
vnet_name                = "vnet-dpn-azure-uks-01"
vnet_resource_group_name = "rg-dpn-azure-uks-01"
location                 = "UK South"
location_short           = "uks"
environment              = "dev"
instance_number          = "01"

# Subnet Configuration
# VNet: 10.0.1.0/24 (256 addresses)
# Tfstate subnet: 10.0.1.144/28 (managed by bootstrap)
subnets = {
  aks = {
    address_prefix                    = "10.0.1.0/27" # 32 addresses
    create_nsg                        = true
    nsg_name                          = "nsg-aks"
    nsg_rules                         = {}
    delegation                        = null
    default_outbound_access_enabled   = true
    private_endpoint_network_policies = "Enabled"
    route_table = {
      name = "rt-aks"
      # Empty by design - point this at your firewall/NVA yourself, e.g.:
      # routes = {
      #   default-egress = {
      #     address_prefix         = "0.0.0.0/0"
      #     next_hop_type          = "VirtualAppliance"
      #     next_hop_in_ip_address = "<your-firewall-private-ip>"
      #   }
      # }
      routes = {}
    }
  }
  keyvault = {
    address_prefix                    = "10.0.1.32/29" # 8 addresses
    create_nsg                        = true
    nsg_name                          = "nsg-keyvault"
    nsg_rules                         = {}
    delegation                        = null
    default_outbound_access_enabled   = true
    private_endpoint_network_policies = "Enabled"
  }
  acr = {
    address_prefix                    = "10.0.1.40/29" # 8 addresses
    create_nsg                        = true
    nsg_name                          = "nsg-acr"
    nsg_rules                         = {}
    delegation                        = null
    default_outbound_access_enabled   = true
    private_endpoint_network_policies = "Enabled"
  }
  loganalytics = {
    address_prefix                    = "10.0.1.48/29" # 8 addresses
    create_nsg                        = true
    nsg_name                          = "nsg-loganalytics"
    nsg_rules                         = {}
    delegation                        = null
    default_outbound_access_enabled   = true
    private_endpoint_network_policies = "Enabled"
  }
  redis = {
    address_prefix                    = "10.0.1.56/29" # 8 addresses
    create_nsg                        = true
    nsg_name                          = "nsg-redis"
    nsg_rules                         = {}
    delegation                        = null
    default_outbound_access_enabled   = true
    private_endpoint_network_policies = "Enabled"
  }
  storage = {
    address_prefix                    = "10.0.1.80/29" # 8 addresses
    create_nsg                        = true
    nsg_name                          = "nsg-storage"
    nsg_rules                         = {}
    delegation                        = null
    default_outbound_access_enabled   = true
    private_endpoint_network_policies = "Enabled"
  }
  vm = {
    address_prefix                    = "10.0.1.128/28" # 16 addresses for Windows VMs
    create_nsg                        = true
    nsg_name                          = "nsg-vm"
    nsg_rules                         = {}
    delegation                        = null
    default_outbound_access_enabled   = true
    private_endpoint_network_policies = "Enabled"
  }
  devstorage = {
    address_prefix                    = "10.0.1.88/29" # 8 addresses for developer storage
    create_nsg                        = true
    nsg_name                          = "nsg-devstorage"
    nsg_rules                         = {}
    delegation                        = null
    default_outbound_access_enabled   = true
    private_endpoint_network_policies = "Enabled"
  }
  snet-evgt-dpn-uks-01 = {
    address_prefix                    = "10.0.1.64/29" # 8 addresses for Event Grid PE
    create_nsg                        = true
    nsg_name                          = "nsg-evgt-dpn-uks-01"
    nsg_rules                         = {}
    delegation                        = null
    default_outbound_access_enabled   = true
    private_endpoint_network_policies = "Enabled"
  }
  snet-sb-dpn-uks-01 = {
    address_prefix                    = "10.0.1.72/29" # 8 addresses for Service Bus PE
    create_nsg                        = true
    nsg_name                          = "nsg-sb-dpn-uks-01"
    nsg_rules                         = {}
    delegation                        = null
    default_outbound_access_enabled   = true
    private_endpoint_network_policies = "Enabled"
  }
  snet-stfs-dpn-uks-01 = {
    address_prefix                    = "10.0.1.192/29" # 8 addresses for file scanning service storage PE
    create_nsg                        = true
    nsg_name                          = "nsg-stfs-dpn-uks-01"
    nsg_rules                         = {}
    delegation                        = null
    default_outbound_access_enabled   = true
    private_endpoint_network_policies = "Enabled"
  }
  # tfstate subnet: 10.0.1.144/28 (managed by bootstrap pipeline)
  # Excluded from Terraform to avoid conflicts with bootstrap-created resources
}

# Diagnostic Settings
enable_diagnostic_settings = true

# ========================================
# Log Analytics
# ========================================
log_analytics_workspace_name      = "law-dpn-azure-uks-01"
log_analytics_resource_group_name = "rg-law-dpn-azure-uks-01"
log_analytics_retention_in_days   = 730
log_analytics_sku                 = "PerGB2018"
log_analytics_identity_type       = "SystemAssigned"

# ========================================
# Key Vault
# ========================================
keyvault_name                            = "kv-dpn-azure-uks-01"
keyvault_resource_group_name             = "rg-kv-dpn-azure-uks-01"
keyvault_public_network_access_enabled   = false
keyvault_sku_name                        = "standard"
keyvault_soft_delete_retention_days      = 90
keyvault_purge_protection_enabled        = true
keyvault_enabled_for_disk_encryption     = true
keyvault_enabled_for_deployment          = true
keyvault_enabled_for_template_deployment = true
keyvault_rbac_authorization_enabled      = true
keyvault_network_acls_bypass             = "AzureServices"
keyvault_network_acls_default_action     = "Deny"
keyvault_network_acls_enabled            = true
keyvault_allowed_ip_ranges               = []
keyvault_allowed_subnet_ids              = []
keyvault_admin_object_ids                = []
keyvault_secrets_officer_object_ids      = ["00000000-0000-0000-0000-000000000000"] # Pipeline SPN object ID (VM password storage)
keyvault_secrets_user_object_ids         = ["00000000-0000-0000-0000-000000000000"] # Dev team SPN object ID
keyvault_initial_secrets                 = {}
# Shared customer-managed key (CMK) used to encrypt every resource below that
# supports it (ACR, AKS node disks + etcd/Secrets, Service Bus, VM OS disk, and
# the three storage accounts). Split into separate per-resource keys instead if
# your compliance framework requires key isolation.
keyvault_initial_keys = {
  "cmk-key" = {
    key_type = "RSA"
    key_size = 3072
    key_opts = ["wrapKey", "unwrapKey", "encrypt", "decrypt", "sign", "verify"]
    # Required by this root variable's type, but the keyvault module itself has no
    # enable_rotation field - it's silently dropped on conversion into the module
    # call, and rotation_* below governs the keyvault module's rotation policy
    # regardless of this value.
    enable_rotation               = true
    rotation_time_before_expiry   = "P30D"
    rotation_expire_after         = "P90D"
    rotation_notify_before_expiry = "P29D"
  }
}

# Self-signed Notation signing certificate for AKS image signature verification (Ratify)
keyvault_initial_certificates = {
  notation-signing-cert = {
    key_type                 = "RSA"
    key_size                 = 3072
    exportable               = false
    key_usage                = ["digitalSignature"]
    subject                  = "CN=notation-signing-dpn-azure-001"
    validity_in_months       = 24
    renew_days_before_expiry = 30
  }
}

# ========================================
# Azure Container Registry
# ========================================
acr_name                          = "acrdpnazureuks01"
acr_resource_group_name           = "rg-acr-dpn-azure-uks-01"
acr_public_network_access_enabled = false
acr_sku                           = "Premium"
acr_admin_enabled                 = false
acr_anonymous_pull_enabled        = false
acr_zone_redundancy_enabled       = true
acr_network_rules_enabled         = true
acr_network_rule_default_action   = "Deny"
acr_allowed_ip_ranges             = []
acr_retention_policy_enabled      = true
acr_retention_policy_days         = 7
acr_trust_policy_enabled          = false
acr_encryption_enabled            = true # CMK via keyvault_initial_keys["cmk-key"] above
acr_create_scope_maps             = false
acr_webhooks                      = {}
acr_georeplications               = {}

# ========================================
# AKS Application Cluster
# ========================================
aks_name                = "aks-dpn-azure-uks-01"
aks_resource_group_name = "rg-aks-dpn-azure-uks-01"
aks_node_resource_group = "rg-aks-dpn-azure-uks-01-nodes"
aks_vnet_subnet_name    = "aks"
aks_kubernetes_version  = "1.33"
aks_private_dns_zone_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-pdns-prd-uks-01/providers/Microsoft.Network/privateDnsZones/privatelink.uksouth.azmk8s.io"
aks_admin_group = [
  "00000000-0000-0000-0000-000000000000", # AVD group for cluster management
  "00000000-0000-0000-0000-000000000000"  # Azure Kubernetes Service Cluster User Role
]
aks_service_cidr              = "172.16.0.0/16"
aks_dns_service_ip            = "172.16.0.10"
aks_sku_tier                  = "Standard"
aks_vm_size                   = "Standard_D8lds_v6"
aks_node_count                = 3
aks_enable_auto_scaling       = true
aks_min_count                 = 3
aks_max_count                 = 6
aks_automatic_upgrade_channel = "stable"
aks_node_os_upgrade_channel   = "NodeImage"
# Security features
aks_azure_policy_enabled      = true
aks_local_account_disabled    = true
aks_oidc_issuer_enabled       = true
aks_workload_identity_enabled = true
aks_host_encryption_enabled   = true
# Networking
aks_network_plugin    = "azure"
aks_network_policy    = "calico"
aks_load_balancer_sku = "standard"
# Private cluster settings
aks_private_cluster_enabled = true
# Workload node pool (disabled by default)
aks_enable_workload_node_pool  = false
aks_workload_node_pool_vm_size = "Standard_D8lds_v6"
aks_workload_node_pool_count   = 3
aks_workload_node_pool_taints  = []
# Node pool configuration
aks_default_node_pool_name                     = "default"
aks_workload_node_pool_name                    = "workload"
aks_workload_node_pool_host_encryption_enabled = true
aks_workload_node_pool_label_key               = "workload"
aks_workload_node_pool_label_value             = "true"
aks_acr_pull_role_name                         = "AcrPull"
aks_user_assigned_identity_type                = "UserAssigned"
aks_diagnostic_all_metrics_category            = "AllMetrics"
aks_diagnostic_all_logs_category_group         = "allLogs"
aks_enable_diagnostic_settings                 = true
# Service Mesh (Istio)
aks_service_mesh_mode      = "Istio"
aks_service_mesh_revisions = ["asm-1-27"]
# Identity
aks_identity_type = "UserAssigned"
# HTTP application routing (deprecated, disabled)
aks_http_application_routing_enabled = false
# CMK for node OS disks + etcd/Secrets, via keyvault_initial_keys["cmk-key"] above.
# ForceNew: only takes effect at cluster creation.
aks_encryption_enabled = true
# Node pool zones (spread the node pool across all 3 UK South availability zones.
# Changing this on an existing node pool forces the pool to be recreated)
aks_node_pool_zones = ["1", "2", "3"]
# Upgrade settings
aks_max_surge                     = "10%"
aks_drain_timeout_in_minutes      = 0
aks_node_soak_duration_in_minutes = 0
# Network overlay mode
aks_network_plugin_mode = "overlay"
# Key Vault secrets provider
aks_secret_rotation_enabled  = true
aks_secret_rotation_interval = "2m"
# Workload node pool zones (see note above; applies only when the workload pool is enabled)
aks_workload_node_pool_zones = ["1", "2", "3"]
# Azure RBAC enabled
aks_azure_rbac_enabled = true

# ========================================
# Connectivity (Private DNS)
# ========================================
connectivity_subscription_id    = "00000000-0000-0000-0000-000000000000"
private_dns_zone_resource_group = "rg-pdns-prd-uks-01"

# ========================================
# Developer Storage Account
# ========================================
dev_storage_account_name                  = "stdevdpnazureuks01"
dev_storage_resource_group_name           = "rg-stdev-dpn-azure-uks-01"
dev_storage_account_tier                  = "Standard"
dev_storage_replication_type              = "LRS"
dev_storage_account_kind                  = "StorageV2"
dev_storage_access_tier                   = "Hot"
dev_storage_public_network_access_enabled = false
dev_storage_min_tls_version               = "TLS1_2"
dev_storage_versioning_enabled            = true
dev_storage_blob_retention_days           = 7
dev_storage_container_retention_days      = 7
dev_team_spn_object_id                    = "00000000-0000-0000-0000-000000000000"
dev_storage_create_blob_endpoint          = true
dev_storage_enable_diagnostic_settings    = true
dev_storage_encryption_enabled            = true # CMK via keyvault_initial_keys["cmk-key"] above

# Optional: managed identities of other clusters that need AcrPull on this ACR
aks_external_acr_pull_principal_ids = [] # No external ACR pull principals needed

# ========================================
# Workload Identity Configuration
# ========================================
workload_identity_name                     = "id-aks-workload-dpn-azure-uks-01"
workload_identity_namespace                = "default"
workload_identity_service_account_name     = "workload-identity-sa"
workload_identity_key_vault_access_enabled = true

# ========================================
# Windows Virtual Machine
# ========================================
vm_name                                 = "vm-dpn-azure-uks-01"
vm_resource_group_name                  = "rg-vm-dpn-azure-uks-01"
vm_size                                 = "Standard_D2lds_v6"
vm_computer_name                        = "dpn-vm01"
vm_admin_username                       = "azureuser"
vm_admin_password                       = null
vm_admin_password_secret_name           = "vm-dpn-azure-uks-01-admin-password"
vm_subnet_name                          = "vm"
vm_private_ip_allocation                = "Dynamic"
vm_private_ip_address                   = null
vm_create_nsg                           = true
vm_os_disk_caching                      = "ReadWrite"
vm_os_disk_storage_account_type         = "Premium_LRS"
vm_os_disk_size_gb                      = 127
vm_image_publisher                      = "MicrosoftWindowsServer"
vm_image_offer                          = "WindowsServer"
vm_image_sku                            = "2022-datacenter-azure-edition"
vm_image_version                        = "latest"
vm_identity_type                        = "SystemAssigned"
vm_enable_boot_diagnostics              = true
vm_boot_diagnostics_storage_account_uri = null
vm_patch_mode                           = "AutomaticByPlatform"
vm_patch_assessment_mode                = "AutomaticByPlatform"
vm_enable_automatic_updates             = true
vm_encryption_at_host_enabled           = true
vm_secure_boot_enabled                  = true
vm_vtpm_enabled                         = true
vm_license_type                         = "None"
vm_timezone                             = "GMT Standard Time"
vm_availability_zone                    = null
vm_enable_diagnostic_settings           = true
vm_encryption_enabled                   = true # CMK via keyvault_initial_keys["cmk-key"] above

# ========================================
# Azure Bastion (optional - see the comment on bastion_enabled in variables.tf)
# ========================================
bastion_enabled                    = true
bastion_resource_group_name        = "rg-bastion-dpn-azure-uks-01"
bastion_host_name                  = "bas-dpn-azure-uks-01"
bastion_public_ip_name             = "pip-bas-dpn-azure-uks-01"
bastion_sku                        = "Developer"
bastion_scale_units                = 2
bastion_copy_paste_enabled         = true
bastion_file_copy_enabled          = true
bastion_tunneling_enabled          = true
bastion_zones                      = []
bastion_enable_diagnostic_settings = true

# ========================================
# Event Grid
# ========================================
event_grid_topic_name                    = "evgt-dpn-uks-01"
event_grid_resource_group_name           = "rg-evgt-dpn-uks-01"
event_grid_local_auth_enabled            = false
event_grid_public_network_access_enabled = true
event_grid_enable_diagnostic_settings    = true

# 00000000-0000-0000-0000-000000000000 = Data Receiver SPN (EventGrid Data Receiver)
# 00000000-0000-0000-0000-000000000000 = Data Sender SPN (EventGrid Data Sender)
# 00000000-0000-0000-0000-000000000000 = Default/team SPN (EventGrid Contributor)
event_grid_data_receiver_principal_ids = ["00000000-0000-0000-0000-000000000000"]
event_grid_data_sender_principal_ids   = ["00000000-0000-0000-0000-000000000000"]
event_grid_contributor_principal_ids   = ["00000000-0000-0000-0000-000000000000"]

# ========================================
# Service Bus
# ========================================
service_bus_namespace_name                = "sb-dpn-uks-01"
service_bus_resource_group_name           = "rg-sb-dpn-uks-01"
service_bus_sku                           = "Premium"
service_bus_capacity                      = 1
service_bus_premium_messaging_partitions  = 1
service_bus_public_network_access_enabled = false
service_bus_local_auth_enabled            = false
service_bus_minimum_tls_version           = "1.2"
service_bus_enable_diagnostic_settings    = true
service_bus_encryption_enabled            = true # CMK via keyvault_initial_keys["cmk-key"] above (Premium SKU only)

# 00000000-0000-0000-0000-000000000000 = Data Receiver SPN (Azure Service Bus Data Receiver)
# 00000000-0000-0000-0000-000000000000 = Data Sender SPN (Azure Service Bus Data Sender)
# 00000000-0000-0000-0000-000000000000 = Default/team SPN (Azure Service Bus Data Owner)
service_bus_data_receiver_principal_ids = ["00000000-0000-0000-0000-000000000000"]
service_bus_data_sender_principal_ids   = ["00000000-0000-0000-0000-000000000000"]
service_bus_data_owner_principal_ids    = ["00000000-0000-0000-0000-000000000000"]

service_bus_queues = {}

# ========================================
# File Scanning Service Storage Account
# ========================================
file_scanning_service_storage_account_name                  = "stfsdpnuks01"
file_scanning_service_storage_resource_group_name           = "rg-stfs-dpn-uks-01"
file_scanning_service_storage_account_tier                  = "Standard"
file_scanning_service_storage_replication_type              = "LRS"
file_scanning_service_storage_account_kind                  = "StorageV2"
file_scanning_service_storage_access_tier                   = "Hot"
file_scanning_service_storage_public_network_access_enabled = false
file_scanning_service_storage_min_tls_version               = "TLS1_2"
file_scanning_service_storage_versioning_enabled            = true
file_scanning_service_storage_blob_retention_days           = 7
file_scanning_service_storage_container_retention_days      = 7
file_scanning_service_storage_dev_team_spn_object_id        = "00000000-0000-0000-0000-000000000000"
file_scanning_service_storage_create_blob_endpoint          = true
file_scanning_service_storage_file_share_name               = ""
file_scanning_service_storage_file_share_quota_gb           = 1
file_scanning_service_storage_create_file_endpoint          = false
file_scanning_service_storage_enable_diagnostic_settings    = true
file_scanning_service_storage_encryption_enabled            = true # CMK via keyvault_initial_keys["cmk-key"] above

# 00000000-0000-0000-0000-000000000000 = Data Receiver SPN (Storage Blob Data Reader)
# 00000000-0000-0000-0000-000000000000 = Default/team SPN (Storage Blob Data Contributor)
file_scanning_service_storage_data_receiver_principal_ids = ["00000000-0000-0000-0000-000000000000"]

# ========================================
# Observability Logging Storage Account
# ========================================
observability_logging_storage_account_name                  = "stobsdpnuks01"
observability_logging_storage_resource_group_name           = "rg-obs-dpn-uks-01"
observability_logging_storage_account_tier                  = "Standard"
observability_logging_storage_replication_type              = "LRS"
observability_logging_storage_account_kind                  = "StorageV2"
observability_logging_storage_access_tier                   = "Hot"
observability_logging_storage_public_network_access_enabled = false
observability_logging_storage_min_tls_version               = "TLS1_2"
observability_logging_storage_versioning_enabled            = true
observability_logging_storage_blob_retention_days           = 7
observability_logging_storage_container_retention_days      = 7
observability_logging_storage_dev_team_spn_object_id        = "00000000-0000-0000-0000-000000000000"
observability_logging_storage_create_blob_endpoint          = true
observability_logging_storage_file_share_name               = ""
observability_logging_storage_file_share_quota_gb           = 1
observability_logging_storage_create_file_endpoint          = false
observability_logging_storage_enable_diagnostic_settings    = true
observability_logging_storage_encryption_enabled            = true # CMK via keyvault_initial_keys["cmk-key"] above
observability_logging_storage_subnet_name                   = "snet-stfs-dpn-uks-01"

observability_logging_storage_data_receiver_principal_ids    = []
observability_logging_storage_data_contributor_principal_ids = []

# ========================================
# Tags
# ========================================
tags = {
  ApplicationOwner = "owner@example.com"
  Environment      = "production"
  Project          = "DPN"
  ManagedBy        = "Terraform"
  Owner            = "Platform-Team"
}
