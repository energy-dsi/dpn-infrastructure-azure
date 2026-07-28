# ========================================
# User-Assigned Managed Identity for Workload Identity
# ========================================
resource "azurerm_user_assigned_identity" "workload_identity" {
  name                = var.identity_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# ========================================
# Federated Identity Credential (Links K8s SA to Azure AD)
# ========================================
resource "azurerm_federated_identity_credential" "aks" {
  name                = "${var.identity_name}-federated"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.workload_identity.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.oidc_issuer_url
  subject             = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
}

# ========================================
# Key Vault RBAC - Secrets User Role
# ========================================
resource "azurerm_role_assignment" "key_vault_secrets" {
  count                = var.enable_key_vault_access ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
}
