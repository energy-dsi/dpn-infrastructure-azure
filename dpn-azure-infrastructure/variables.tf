# ========================================
# Core Infrastructure Variables
# ========================================

variable "subscription_id" {
  description = "The subscription ID to deploy resources into"
  type        = string
}

variable "location" {
  description = "The location/region where resources will be created"
  type        = string
}

variable "location_short" {
  description = "Short name for location (e.g., uks for UK South)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming (e.g., dpn)"
  type        = string
  default     = "dpn"
}

variable "environment" {
  description = "Environment name for resource naming (e.g., dev, test, prod)"
  type        = string
}

variable "instance_number" {
  description = "Instance number for resource naming (e.g., 01, 02)"
  type        = string
}

variable "tags" {
  description = "Common tags to assign to all resources"
  type        = map(string)
}

# ========================================
# Networking Variables
# ========================================

variable "vnet_name" {
  description = "The name of the existing virtual network"
  type        = string
}

variable "vnet_resource_group_name" {
  description = "The resource group containing the virtual network"
  type        = string
}

variable "subnets" {
  description = "Map of subnets to create in the virtual network"
  type = map(object({
    address_prefix                    = string
    default_outbound_access_enabled   = optional(bool, true)
    private_endpoint_network_policies = optional(string, "Disabled")
    create_nsg                        = optional(bool, false)
    nsg_name                          = optional(string)
    delegation = optional(object({
      name                       = string
      service_delegation_name    = string
      service_delegation_actions = list(string)
    }))
    nsg_rules = optional(map(object({
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), {})
  }))
}

# ========================================
# Shared Service Variables
# ========================================

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  type        = string
}

variable "log_analytics_resource_group_name" {
  description = "Resource group name for Log Analytics workspace"
  type        = string
}

variable "log_analytics_retention_in_days" {
  description = "Number of days to retain data in Log Analytics (30-730)"
  type        = number
}

variable "log_analytics_sku" {
  description = "SKU for Log Analytics workspace"
  type        = string
}

variable "log_analytics_identity_type" {
  description = "Type of managed identity for Log Analytics workspace"
  type        = string
}

variable "private_dns_zone_subscription_id" {
  description = "Subscription ID where central Private DNS zones are located"
  type        = string
}

variable "private_dns_zone_resource_group" {
  description = "Resource group name for central Private DNS zones"
  type        = string
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for resources"
  type        = bool
}

# ========================================
# Resource-Specific Variables
# ========================================

variable "keyvault_name" {
  description = "Name of the Key Vault"
  type        = string
}

variable "keyvault_resource_group_name" {
  description = "Resource group name for Key Vault"
  type        = string
}

variable "keyvault_public_network_access_enabled" {
  description = "Enable public network access for Key Vault"
  type        = bool
}

variable "keyvault_sku_name" {
  description = "SKU name of the Key Vault (standard or premium)"
  type        = string
}

variable "keyvault_soft_delete_retention_days" {
  description = "Number of days that items should be retained once soft deleted (7-90)"
  type        = number
}

variable "keyvault_purge_protection_enabled" {
  description = "Enable purge protection for Key Vault"
  type        = bool
}

variable "keyvault_enabled_for_disk_encryption" {
  description = "Enable Azure Disk Encryption to retrieve secrets"
  type        = bool
}

variable "keyvault_enabled_for_deployment" {
  description = "Enable Azure VMs to retrieve certificates"
  type        = bool
}

variable "keyvault_enabled_for_template_deployment" {
  description = "Enable ARM to retrieve secrets"
  type        = bool
}

variable "keyvault_network_acls_bypass" {
  description = "Specifies which traffic can bypass network rules (AzureServices or None)"
  type        = string
}

variable "keyvault_network_acls_default_action" {
  description = "Default action when no rule matches (Allow or Deny)"
  type        = string
}

variable "keyvault_rbac_authorization_enabled" {
  description = "Enable RBAC authorization for Key Vault"
  type        = bool
}

variable "keyvault_network_acls_enabled" {
  description = "Enable network ACLs for Key Vault"
  type        = bool
}

variable "keyvault_allowed_ip_ranges" {
  description = "List of IP ranges allowed to access Key Vault"
  type        = list(string)
}

variable "keyvault_allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access Key Vault"
  type        = list(string)
}

variable "keyvault_admin_object_ids" {
  description = "List of object IDs to grant Key Vault Administrator role"
  type        = list(string)
}

variable "keyvault_secrets_officer_object_ids" {
  description = "List of object IDs to grant Key Vault Secrets Officer role"
  type        = list(string)
}

variable "keyvault_secrets_user_object_ids" {
  description = "List of object IDs to grant Key Vault Secrets User role"
  type        = list(string)
}

variable "keyvault_initial_secrets" {
  description = "Map of initial secrets to create in Key Vault. Set expiration_date (RFC3339) on every entry - secrets without one never expire."
  type = map(object({
    value           = string
    expiration_date = optional(string)
  }))
}

variable "keyvault_initial_keys" {
  description = "Map of initial keys to create in Key Vault. Set expiration_date (RFC3339) on every entry - keys without one never expire."
  type = map(object({
    key_type                      = string
    key_size                      = number
    key_opts                      = list(string)
    expiration_date               = optional(string)
    enable_rotation               = optional(bool, true)
    rotation_time_before_expiry   = optional(string, "P30D")
    rotation_expire_after         = optional(string, "P90D")
    rotation_notify_before_expiry = optional(string, "P29D")
  }))
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
}

variable "acr_resource_group_name" {
  description = "Resource group name for Azure Container Registry"
  type        = string
}

variable "acr_public_network_access_enabled" {
  description = "Enable public network access for ACR"
  type        = bool
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry (Basic, Standard, Premium)"
  type        = string
}

variable "acr_admin_enabled" {
  description = "Enable admin account for ACR"
  type        = bool
}

variable "acr_zone_redundancy_enabled" {
  description = "Enable zone redundancy for ACR (Premium SKU only)"
  type        = bool
}

variable "acr_retention_policy_enabled" {
  description = "Enable retention policy for untagged manifests (Premium SKU only)"
  type        = bool
}

variable "acr_retention_policy_days" {
  description = "Number of days to retain untagged manifests"
  type        = number
}

variable "acr_quarantine_policy_enabled" {
  description = "Enable ACR quarantine policy (Premium SKU only). Every pushed image is held in a locked, unpullable state until an external scanning integration explicitly marks it as passed. Only enable this if you have such an integration wired up - otherwise every pushed image becomes permanently stuck and undeployable."
  type        = bool
  default     = false
}

variable "acr_georeplications" {
  description = "Map of geo-replication configurations (Premium SKU only)"
  type = map(object({
    location                  = string
    zone_redundancy_enabled   = bool
    regional_endpoint_enabled = bool
  }))
}

variable "acr_anonymous_pull_enabled" {
  description = "Allow anonymous pull access to ACR"
  type        = bool
}

variable "acr_network_rules_enabled" {
  description = "Enable network rules for ACR"
  type        = bool
}

variable "acr_network_rule_default_action" {
  description = "Default action for ACR network rules (Allow or Deny)"
  type        = string
}

variable "acr_allowed_ip_ranges" {
  description = "List of IP ranges allowed to access ACR"
  type        = list(string)
}

variable "acr_encryption_enabled" {
  description = "Enable customer-managed key encryption for ACR"
  type        = bool
}

variable "acr_create_scope_maps" {
  description = "Create default scope maps for ACR"
  type        = bool
}

variable "acr_webhooks" {
  description = "Map of webhooks to create for ACR"
  type = map(object({
    service_uri    = string
    status         = string
    scope          = string
    actions        = list(string)
    custom_headers = map(string)
  }))
}

variable "aks_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "aks_resource_group_name" {
  description = "Resource group name for AKS cluster"
  type        = string
}

variable "aks_node_resource_group" {
  description = "Resource group name for AKS node infrastructure (VMs, disks, etc.)"
  type        = string
}

variable "aks_private_cluster_enabled" {
  description = "Enable private cluster (API server accessible only via private endpoint)"
  type        = bool
}

variable "aks_enable_diagnostic_settings" {
  description = "Enable diagnostic settings for AKS cluster"
  type        = bool
}

variable "aks_vnet_subnet_name" {
  description = "Name of the subnet where AKS nodes will be deployed"
  type        = string
}

variable "keyvault_vnet_subnet_name" {
  description = "Name of the subnet for the Key Vault private endpoint"
  type        = string
}

variable "acr_vnet_subnet_name" {
  description = "Name of the subnet for the ACR private endpoint"
  type        = string
}

variable "aks_kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
}

variable "aks_private_dns_zone_id" {
  description = "Resource ID of the private DNS zone for private AKS cluster"
  type        = string
}

variable "aks_admin_group" {
  description = "Object IDs of Azure AD groups/principals granted AKS admin access: ARM-level Cluster User Role (kubeconfig fetch) plus Kubernetes RBAC Writer (cluster-wide kubectl/helm read-write, excluding cluster-scoped security config)"
  type        = list(string)
}

variable "aks_service_cidr" {
  description = "CIDR block for Kubernetes services"
  type        = string
}

variable "aks_dns_service_ip" {
  description = "IP address for Kubernetes DNS service (must be within service_cidr)"
  type        = string
}

variable "aks_sku_tier" {
  description = "SKU tier for the AKS cluster (Free, Standard, Premium)"
  type        = string
}

variable "aks_vm_size" {
  description = "VM size for AKS default node pool"
  type        = string
}

variable "aks_node_count" {
  description = "Number of nodes in the AKS default node pool"
  type        = number
}

variable "aks_enable_auto_scaling" {
  description = "Enable autoscaling for the AKS default node pool"
  type        = bool
  default     = false
}

variable "aks_min_count" {
  description = "Minimum number of nodes when autoscaling is enabled for AKS"
  type        = number
  default     = null
}

variable "aks_max_count" {
  description = "Maximum number of nodes when autoscaling is enabled for AKS"
  type        = number
  default     = null
}

variable "aks_max_pods" {
  description = "Maximum pods per node on both AKS node pools. Safe to set well above the Azure CNI default (30) when aks_network_plugin_mode = \"overlay\"."
  type        = number
  default     = 50
}

variable "aks_only_critical_addons_enabled" {
  description = "Taint the default node pool with CriticalAddonsOnly=true:NoSchedule so only AKS-managed system pods schedule there. Only takes effect when aks_enable_workload_node_pool is also true, otherwise there would be no pool left for customer workloads."
  type        = bool
  default     = true
}

variable "aks_automatic_upgrade_channel" {
  description = "Upgrade channel for Kubernetes (patch, rapid, node-image, stable)"
  type        = string
}

variable "aks_node_os_upgrade_channel" {
  description = "Upgrade channel for node OS (NodeImage, None, SecurityPatch, Unmanaged)"
  type        = string
}

variable "aks_azure_policy_enabled" {
  description = "Enable Azure Policy for AKS cluster"
  type        = bool
}

variable "aks_local_account_disabled" {
  description = "Disable local accounts (enforce Azure AD only)"
  type        = bool
}

variable "aks_oidc_issuer_enabled" {
  description = "Enable OIDC issuer for workload identity"
  type        = bool
}

variable "aks_workload_identity_enabled" {
  description = "Enable workload identity"
  type        = bool
}

variable "aks_host_encryption_enabled" {
  description = "Enable host-based encryption for AKS nodes"
  type        = bool
}

variable "aks_network_plugin" {
  description = "Network plugin for AKS (azure or kubenet)"
  type        = string
}

variable "aks_network_policy" {
  description = "Network policy for AKS (azure, calico, or cilium)"
  type        = string
}

variable "aks_load_balancer_sku" {
  description = "SKU for load balancer (basic or standard)"
  type        = string
}

variable "aks_enable_workload_node_pool" {
  description = "Enable additional workload node pool for application workloads"
  type        = bool
}

variable "aks_service_mesh_mode" {
  description = "Service mesh mode (Istio or Disabled)"
  type        = string
}

variable "aks_service_mesh_revisions" {
  description = "List of Istio revisions to enable"
  type        = list(string)
}

variable "aks_identity_type" {
  description = "Type of managed identity (SystemAssigned or UserAssigned)"
  type        = string
}

variable "aks_http_application_routing_enabled" {
  description = "Enable HTTP application routing (deprecated)"
  type        = bool
}

variable "aks_node_pool_zones" {
  description = "Availability zones for the default node pool"
  type        = list(number)
}

variable "aks_max_surge" {
  description = "Maximum number or percentage of nodes which will be added during an upgrade"
  type        = string
}

variable "aks_drain_timeout_in_minutes" {
  description = "The amount of time in minutes to wait on eviction of pods"
  type        = number
}

variable "aks_node_soak_duration_in_minutes" {
  description = "The amount of time in minutes to wait after draining a node"
  type        = number
}

variable "aks_network_plugin_mode" {
  description = "Network plugin mode (overlay or blank for default)"
  type        = string
}

variable "aks_secret_rotation_enabled" {
  description = "Enable automatic rotation of Key Vault secrets"
  type        = bool
}

variable "aks_secret_rotation_interval" {
  description = "Rotation poll interval for Key Vault secrets"
  type        = string
}

variable "aks_workload_node_pool_zones" {
  description = "Availability zones for the workload node pool"
  type        = list(number)
}

variable "aks_azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
}

variable "aks_encryption_enabled" {
  description = "Enable customer-managed key (CMK) encryption for AKS node OS disks and etcd/Secrets"
  type        = bool
  default     = false
}

variable "aks_workload_node_pool_vm_size" {
  description = "VM size for AKS workload node pool"
  type        = string
}

variable "aks_workload_node_pool_count" {
  description = "Number of nodes in the AKS workload node pool"
  type        = number
}

variable "aks_workload_node_pool_taints" {
  description = "Taints to apply to AKS workload node pool nodes"
  type        = list(string)
}

variable "aks_default_node_pool_name" {
  description = "Name of the default AKS node pool"
  type        = string
}

variable "aks_workload_node_pool_name" {
  description = "Name of the workload AKS node pool"
  type        = string
}

variable "aks_workload_node_pool_host_encryption_enabled" {
  description = "Enable host-based encryption for workload node pool nodes"
  type        = bool
}

variable "aks_workload_node_pool_label_key" {
  description = "Label key for workload node pool"
  type        = string
}

variable "aks_workload_node_pool_label_value" {
  description = "Label value for workload node pool"
  type        = string
}

variable "aks_acr_pull_role_name" {
  description = "Role definition name for ACR pull access"
  type        = string
}

variable "aks_user_assigned_identity_type" {
  description = "Identity type for User Assigned Identity (required for custom private DNS zone)"
  type        = string
}

variable "aks_diagnostic_all_metrics_category" {
  description = "Category name for all metrics in diagnostic settings"
  type        = string
}

variable "aks_diagnostic_all_logs_category_group" {
  description = "Category group name for all logs in diagnostic settings"
  type        = string
}

variable "aks_external_acr_pull_principal_ids" {
  description = "List of external principal IDs to grant AcrPull on the DPN ACR"
  type        = list(string)
  default     = []
}

# ========================================
# Storage Account Variables
# ========================================

variable "storage_versioning_enabled" {
  description = "Enable blob versioning for storage account"
  type        = bool
  default     = true
}

variable "storage_allow_nested_items_to_be_public" {
  description = "Allow or disallow public access to all blobs or containers"
  type        = bool
  default     = false
}

variable "storage_tags" {
  description = "Tags for Storage Account resources"
  type        = map(string)
  default     = {}
}

variable "storage_network_rules_default_action" {
  description = "Default action for storage network rules"
  type        = string
  default     = "Deny"
}

variable "storage_network_rules_bypass" {
  description = "Bypass rules for storage network ACLs"
  type        = list(string)
  default     = ["AzureServices"]
}

# ========================================
# Developer Storage Account Variables
# ========================================

variable "dev_storage_account_name" {
  description = "Name of the developer storage account"
  type        = string
}

variable "dev_storage_resource_group_name" {
  description = "Resource group name for developer storage"
  type        = string
}

variable "dev_storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "dev_storage_replication_type" {
  description = "Storage replication type"
  type        = string
  default     = "LRS"
}

variable "dev_storage_account_kind" {
  description = "Storage account kind"
  type        = string
  default     = "StorageV2"
}

variable "dev_storage_access_tier" {
  description = "Storage access tier"
  type        = string
  default     = "Hot"
}

variable "dev_storage_public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "dev_storage_min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"
}

variable "dev_storage_versioning_enabled" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "dev_storage_blob_retention_days" {
  description = "Blob retention days"
  type        = number
  default     = 7
}

variable "dev_storage_container_retention_days" {
  description = "Container retention days"
  type        = number
  default     = 7
}

variable "dev_team_spn_object_id" {
  description = "Object ID of dev team SPN"
  type        = string
}

variable "dev_storage_create_blob_endpoint" {
  description = "Create blob private endpoint"
  type        = bool
  default     = true
}

variable "dev_storage_create_file_share" {
  description = "Create an Azure Files share on the dev storage account"
  type        = bool
  default     = false
}

variable "dev_storage_file_share_name" {
  description = "Name of the Azure Files share"
  type        = string
  default     = ""
}

variable "dev_storage_file_share_quota_gb" {
  description = "Quota, in GB, for the Azure Files share"
  type        = number
  default     = 100
}

variable "dev_storage_create_file_endpoint" {
  description = "Create file (Azure Files) private endpoint on the dev storage account"
  type        = bool
  default     = false
}

variable "dev_storage_enable_diagnostic_settings" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = true
}

variable "dev_storage_encryption_enabled" {
  description = "Enable customer-managed key (CMK) encryption for the developer storage account"
  type        = bool
  default     = false
}

variable "dev_storage_blob_contributor_additional_principal_ids" {
  description = "Additional principal IDs to grant Storage Blob Data Contributor on the dev storage account"
  type        = list(string)
  default     = []
}

# ========================================
# Event Grid Variables
# ========================================

variable "event_grid_topic_name" {
  description = "Name of the Event Grid custom topic"
  type        = string
}

variable "event_grid_resource_group_name" {
  description = "Resource group name for Event Grid"
  type        = string
}

variable "event_grid_local_auth_enabled" {
  description = "Enable local authentication for Event Grid"
  type        = bool
  default     = false
}

variable "event_grid_public_network_access_enabled" {
  description = "Enable public network access for Event Grid. Microsoft Defender for Storage cannot deliver malware-scan-result events to a private-endpoint-only topic (confirmed Microsoft/platform limitation) - keep this true if this topic receives Defender for Storage events."
  type        = bool
  default     = true
}

variable "event_grid_enable_diagnostic_settings" {
  description = "Enable diagnostic settings for Event Grid"
  type        = bool
  default     = true
}

variable "event_grid_data_receiver_principal_ids" {
  description = "Principal IDs to grant EventGrid Data Receiver role"
  type        = list(string)
  default     = []
}

variable "event_grid_data_sender_principal_ids" {
  description = "Principal IDs to grant EventGrid Data Sender role"
  type        = list(string)
  default     = []
}

variable "event_grid_contributor_principal_ids" {
  description = "Principal IDs to grant EventGrid Contributor role"
  type        = list(string)
  default     = []
}

variable "event_grid_subnet_name" {
  description = "Subnet name for Event Grid private endpoint"
  type        = string
}

# ========================================
# Service Bus Variables
# ========================================

variable "service_bus_namespace_name" {
  description = "Name of the Service Bus namespace"
  type        = string
}

variable "service_bus_resource_group_name" {
  description = "Resource group name for Service Bus"
  type        = string
}

variable "service_bus_sku" {
  description = "SKU for Service Bus namespace (Premium required for private endpoints)"
  type        = string
  default     = "Premium"
}

variable "service_bus_capacity" {
  description = "Messaging units for Premium tier"
  type        = number
  default     = 1
}

variable "service_bus_premium_messaging_partitions" {
  description = "Number of messaging partitions for Premium tier"
  type        = number
  default     = 1
}

variable "service_bus_public_network_access_enabled" {
  description = "Enable public network access for Service Bus"
  type        = bool
  default     = false
}

variable "service_bus_local_auth_enabled" {
  description = "Enable local authentication (SAS tokens) for Service Bus"
  type        = bool
  default     = false
}

variable "service_bus_trusted_services_allowed" {
  description = "Allow trusted Microsoft services to bypass Service Bus network rules"
  type        = bool
  default     = true
}

variable "service_bus_minimum_tls_version" {
  description = "Minimum TLS version for Service Bus"
  type        = string
  default     = "1.2"
}

variable "service_bus_enable_diagnostic_settings" {
  description = "Enable diagnostic settings for Service Bus"
  type        = bool
  default     = true
}

variable "service_bus_encryption_enabled" {
  description = "Enable customer-managed key (CMK) encryption for Service Bus (Premium SKU only)"
  type        = bool
  default     = false
}

variable "service_bus_data_receiver_principal_ids" {
  description = "Principal IDs to grant Azure Service Bus Data Receiver role"
  type        = list(string)
  default     = []
}

variable "service_bus_data_sender_principal_ids" {
  description = "Principal IDs to grant Azure Service Bus Data Sender role"
  type        = list(string)
  default     = []
}

variable "service_bus_data_owner_principal_ids" {
  description = "Principal IDs to grant Azure Service Bus Data Owner role"
  type        = list(string)
  default     = []
}

variable "service_bus_queues" {
  description = "Map of Service Bus queues to create"
  type = map(object({
    max_size_in_megabytes                = optional(number, 1024)
    default_message_ttl                  = optional(string, "P14D")
    lock_duration                        = optional(string, "PT1M")
    dead_lettering_on_message_expiration = optional(bool, false)
    max_delivery_count                   = optional(number, 10)
    requires_duplicate_detection         = optional(bool, false)
    requires_session                     = optional(bool, false)
    partitioning_enabled                 = optional(bool, false)
  }))
  default = {}
}

variable "service_bus_subnet_name" {
  description = "Subnet name for Service Bus private endpoint"
  type        = string
}

# ========================================
# File Scanning Storage Variables
# ========================================

variable "file_scanning_storage_account_name" {
  description = "Name of the file scanning service storage account"
  type        = string
}

variable "file_scanning_storage_resource_group_name" {
  description = "Resource group name for file scanning storage"
  type        = string
}

variable "file_scanning_storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "file_scanning_storage_replication_type" {
  description = "Storage replication type"
  type        = string
  default     = "LRS"
}

variable "file_scanning_storage_account_kind" {
  description = "Storage account kind"
  type        = string
  default     = "StorageV2"
}

variable "file_scanning_storage_access_tier" {
  description = "Storage access tier"
  type        = string
  default     = "Hot"
}

variable "file_scanning_storage_public_network_access_enabled" {
  description = "Enable public network access for file scanning storage"
  type        = bool
  default     = false
}

variable "file_scanning_storage_min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"
}

variable "file_scanning_storage_versioning_enabled" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "file_scanning_storage_blob_retention_days" {
  description = "Blob retention days"
  type        = number
  default     = 7
}

variable "file_scanning_storage_container_retention_days" {
  description = "Container retention days"
  type        = number
  default     = 7
}

variable "file_scanning_storage_dev_team_spn_object_id" {
  description = "Object ID of dev team SPN for Storage Blob Data Contributor on file scanning storage"
  type        = string
  default     = ""
}

variable "file_scanning_storage_blob_reader_principal_ids" {
  description = "Principal IDs to grant Storage Blob Data Reader on file scanning storage"
  type        = list(string)
  default     = []
}

variable "file_scanning_storage_create_blob_endpoint" {
  description = "Create blob private endpoint for file scanning storage"
  type        = bool
  default     = true
}

variable "file_scanning_storage_enable_diagnostic_settings" {
  description = "Enable diagnostic settings for file scanning storage"
  type        = bool
  default     = true
}

variable "file_scanning_storage_encryption_enabled" {
  description = "Enable customer-managed key (CMK) encryption for the file scanning storage account"
  type        = bool
  default     = false
}

variable "file_scanning_storage_subnet_name" {
  description = "Subnet name for file scanning storage private endpoint"
  type        = string
}

# ========================================
# Observability Logging Storage Variables
# ========================================

variable "observability_logging_storage_account_name" {
  description = "Name of the observability logging storage account"
  type        = string
}

variable "observability_logging_storage_resource_group_name" {
  description = "Resource group name for observability logging storage"
  type        = string
}

variable "observability_logging_storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "observability_logging_storage_replication_type" {
  description = "Storage replication type"
  type        = string
  default     = "LRS"
}

variable "observability_logging_storage_account_kind" {
  description = "Storage account kind"
  type        = string
  default     = "StorageV2"
}

variable "observability_logging_storage_access_tier" {
  description = "Storage access tier"
  type        = string
  default     = "Hot"
}

variable "observability_logging_storage_public_network_access_enabled" {
  description = "Enable public network access for observability logging storage"
  type        = bool
  default     = false
}

variable "observability_logging_storage_min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"
}

variable "observability_logging_storage_versioning_enabled" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "observability_logging_storage_blob_retention_days" {
  description = "Blob retention days"
  type        = number
  default     = 7
}

variable "observability_logging_storage_container_retention_days" {
  description = "Container retention days"
  type        = number
  default     = 7
}

variable "observability_logging_storage_dev_team_spn_object_id" {
  description = "Object ID of dev team SPN for Storage Blob Data Contributor on observability logging storage"
  type        = string
  default     = ""
}

variable "observability_logging_storage_blob_reader_principal_ids" {
  description = "Principal IDs to grant Storage Blob Data Reader on observability logging storage"
  type        = list(string)
  default     = []
}

variable "observability_logging_storage_create_blob_endpoint" {
  description = "Create blob private endpoint for observability logging storage"
  type        = bool
  default     = true
}

variable "observability_logging_storage_enable_diagnostic_settings" {
  description = "Enable diagnostic settings for observability logging storage"
  type        = bool
  default     = true
}

variable "observability_logging_storage_encryption_enabled" {
  description = "Enable customer-managed key (CMK) encryption for the observability logging storage account"
  type        = bool
  default     = false
}

variable "observability_logging_storage_subnet_name" {
  description = "Subnet name for observability logging storage private endpoint"
  type        = string
}

# ========================================
# Workload Identity Variables
# ========================================

variable "workload_identity_name" {
  description = "The name of the user-assigned managed identity for workload identity"
  type        = string
}

variable "workload_identity_namespace" {
  description = "The Kubernetes namespace for the workload identity service account"
  type        = string
  default     = "default"
}

variable "workload_identity_service_account_name" {
  description = "The name of the Kubernetes service account for workload identity"
  type        = string
  default     = "workload-identity-sa"
}

variable "workload_identity_key_vault_access_enabled" {
  description = "Whether to grant the workload identity access to Key Vault"
  type        = bool
  default     = true
}

# ========================================
# Windows VM Variables
# ========================================

variable "vm_name" {
  description = "Name of the Windows VM"
  type        = string
}

variable "vm_resource_group_name" {
  description = "Resource group name for the Windows VM"
  type        = string
}

variable "vm_size" {
  description = "Size of the Windows VM"
  type        = string
}

variable "vm_computer_name" {
  description = "Windows computer name (max 15 characters)"
  type        = string
}

variable "vm_admin_username" {
  description = "Administrator username for the Windows VM"
  type        = string
}

variable "vm_admin_password" {
  description = "Administrator password for the Windows VM (should come from Key Vault)"
  type        = string
  sensitive   = true
}

variable "vm_subnet_name" {
  description = "Name of the subnet for the Windows VM"
  type        = string
}

variable "vm_private_ip_allocation" {
  description = "Private IP allocation method for the VM"
  type        = string
}

variable "vm_private_ip_address" {
  description = "Static private IP address (if allocation is Static)"
  type        = string
}

variable "vm_create_nsg" {
  description = "Whether to create a network security group for the VM"
  type        = bool
}

variable "vm_os_disk_caching" {
  description = "Caching type for the OS disk"
  type        = string
}

variable "vm_os_disk_storage_account_type" {
  description = "Storage account type for the OS disk"
  type        = string
}

variable "vm_os_disk_size_gb" {
  description = "Size of the OS disk in GB"
  type        = number
}

variable "vm_image_publisher" {
  description = "Publisher of the VM image"
  type        = string
}

variable "vm_image_offer" {
  description = "Offer of the VM image"
  type        = string
}

variable "vm_image_sku" {
  description = "SKU of the VM image"
  type        = string
}

variable "vm_image_version" {
  description = "Version of the VM image"
  type        = string
}

variable "vm_identity_type" {
  description = "Identity type for the Windows VM (SystemAssigned, UserAssigned)"
  type        = string
}

variable "vm_admin_username_secret_name" {
  description = "Key Vault secret name that holds the Windows VM administrator username"
  type        = string
  default     = ""
}

variable "vm_admin_password_secret_name" {
  description = "Key Vault secret name that holds the Windows VM administrator password"
  type        = string
  default     = ""
}

variable "vm_enable_boot_diagnostics" {
  description = "Whether to enable boot diagnostics"
  type        = bool
}

variable "vm_boot_diagnostics_storage_account_uri" {
  description = "Storage account URI for boot diagnostics"
  type        = string
}

variable "vm_patch_mode" {
  description = "Patch mode for the VM"
  type        = string
}

variable "vm_patch_assessment_mode" {
  description = "Patch assessment mode for the VM"
  type        = string
}

variable "vm_encryption_at_host_enabled" {
  description = "Whether to enable encryption at host"
  type        = bool
}

variable "vm_enable_automatic_updates" {
  description = "Whether to enable automatic updates for the VM"
  type        = bool
}

variable "vm_secure_boot_enabled" {
  description = "Whether to enable secure boot"
  type        = bool
}

variable "vm_vtpm_enabled" {
  description = "Whether to enable vTPM"
  type        = bool
}

variable "vm_license_type" {
  description = "License type for the VM"
  type        = string
}

variable "vm_timezone" {
  description = "Timezone for the VM"
  type        = string
}

variable "vm_availability_zone" {
  description = "Availability zone for the VM"
  type        = string
}

variable "vm_enable_diagnostic_settings" {
  description = "Whether to enable diagnostic settings for the VM"
  type        = bool
}

variable "vm_encryption_enabled" {
  description = "Enable customer-managed key (CMK) encryption for the VM OS disk via a disk encryption set"
  type        = bool
  default     = false
}

# ========================================
# Azure Bastion (interim jump host access)
# ========================================
variable "bastion_resource_group_name" {
  description = "Resource group name for Azure Bastion"
  type        = string
}

variable "bastion_host_name" {
  description = "Name of the Azure Bastion host"
  type        = string
}

variable "bastion_public_ip_name" {
  description = "Name of the Bastion host's public IP"
  type        = string
}

variable "bastion_sku" {
  description = "Azure Bastion SKU"
  type        = string
  default     = "Standard"
}

variable "bastion_scale_units" {
  description = "Number of Bastion scale units (Standard/Premium only)"
  type        = number
  default     = 2
}

variable "bastion_copy_paste_enabled" {
  description = "Enable copy/paste in Bastion sessions"
  type        = bool
  default     = true
}

variable "bastion_file_copy_enabled" {
  description = "Enable file copy in Bastion sessions"
  type        = bool
  default     = true
}

variable "bastion_tunneling_enabled" {
  description = "Enable native client support (az network bastion tunnel/rdp/ssh)"
  type        = bool
  default     = true
}

variable "bastion_zones" {
  description = "Availability zones for the Bastion host and its public IP"
  type        = list(string)
  default     = []
}

variable "bastion_enable_diagnostic_settings" {
  description = "Enable diagnostic settings streaming Bastion audit logs to Log Analytics"
  type        = bool
  default     = true
}

