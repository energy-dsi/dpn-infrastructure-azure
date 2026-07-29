# ==============================================================================
# TFLint Configuration - DPN Reference Infrastructure
# ==============================================================================
# This config tunes TFLint for a Terraform MONOREPO pattern where:
#
#   1. All modules are LOCAL PATH modules within the same repository.
#      Registry or git-sourced modules are not used.
#      Version pinning applies to registry/git sources only.
#
#   2. Provider requirements are declared ONCE at the root module level.
#      Child modules inherit providers from the root and do not need their own
#      required_version / required_providers blocks.
#
#   3. Module variables are declared for the INTERFACE CONTRACT — they define
#      what callers CAN pass. Some variables are declared but not yet consumed
#      by resource blocks (feature knobs planned but not yet wired up). These
#      are intentional and reviewed before each pre-prod promotion.
#
# Rules are suppressed only when they produce systematic false positives for
# this pattern. All other rules remain enabled.
# ==============================================================================

# No remote plugin install required — runs without internet access on
# self-hosted agents. Re-enable if the azurerm plugin is available:
#
# plugin "azurerm" {
#   enabled = true
#   version = "0.27.0"
#   source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
# }

# ==============================================================================
# Disabled rules: False positives for this monorepo architecture
# ==============================================================================

# ── terraform_required_version ─────────────────────────────────────────────
# Fires on every child module directory that lacks a required_version block.
# Child modules are always invoked by the root; they inherit the constraint
# and do not need their own declaration. Requiring required_version in every
# child module is idiomatic only for independently published modules.
rule "terraform_required_version" {
  enabled = false
}

# ── terraform_required_providers ───────────────────────────────────────────
# Same root cause as terraform_required_version above: TFLint's --recursive
# mode lints each child module directory in isolation, so it cannot see that
# the ROOT module already declares required_providers with a version
# constraint. Every child module inherits this from the root and does not
# redeclare its own required_providers block. Confirmed via local tflint run:
# one warning per module file that references a provider resource
# (modules/aks, ampls, bastion, container_registry, event_grid, keyvault,
# loganalytics, networking, service_bus, storage, vm, workload_identity).
rule "terraform_required_providers" {
  enabled = false
}

# ── terraform_module_pinned_source ─────────────────────────────────────────
# The default mode ("flexible") already ignores local path sources, but
# made explicit here for auditability.
# All module sources in this codebase are LOCAL PATHs: source = "../modules/x"
# There are no registry or git-sourced modules that would require a ref pin.
rule "terraform_module_pinned_source" {
  enabled = false
}

# ── terraform_unused_declarations ─────────────────────────────────────────
# Child module variables.tf files declare the full INTERFACE CONTRACT for the
# module — the complete set of parameters a caller may pass. Some variables
# represent feature knobs that are declared but not yet wired to resource
# attributes because the feature is either conditionally disabled in the
# current environment tier, or planned for a subsequent sprint.
# Action: review this list before pre-prod promotion and either implement
# the feature or explicitly remove both the variable and the caller reference.
rule "terraform_unused_declarations" {
  enabled = false
}
