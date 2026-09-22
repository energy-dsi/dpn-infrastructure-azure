# ========================================
# Workload Identity Module Variables
# ========================================

variable "identity_name" {
  description = "The name of the user-assigned managed identity for workload identity"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where the identity will be created"
  type        = string
}

variable "location" {
  description = "The Azure region where the identity will be created"
  type        = string
}

variable "oidc_issuer_url" {
  description = "The OIDC issuer URL from the AKS cluster"
  type        = string
}

variable "namespace" {
  description = "The Kubernetes namespace where the service account exists"
  type        = string
  default     = "default"
}

variable "service_account_name" {
  description = "The name of the Kubernetes service account to federate with Azure AD"
  type        = string
}

variable "key_vault_id" {
  description = "The ID of the Key Vault to grant access to (optional)"
  type        = string
  default     = ""
}

variable "enable_key_vault_access" {
  description = "Whether to enable Key Vault access for this workload identity"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the managed identity"
  type        = map(string)
  default     = {}
}
