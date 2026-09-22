# AKS Node Pool SKU Upgrade Guide

## ⚠️ CRITICAL: Read This Before Changing VM Sizes

Changing the VM size (SKU) of AKS node pools requires careful planning to avoid service disruption.

## How It Works

The `temporary_name_for_rotation` feature enables zero-downtime node pool upgrades by:

1. **Creating** a temporary node pool with the new VM size
2. **Draining** workloads from the old node pool to the temporary pool
3. **Deleting** the old node pool
4. **Renaming** the temporary pool back to the original name

## Before You Start

### Prerequisites

✅ **ALWAYS run `tofu plan` first** and verify the output shows:
```
# module.aks.azurerm_kubernetes_cluster.aks will be updated in-place
  ~ default_node_pool {
      ~ vm_size = "Standard_D2lds_v6" -> "Standard_D4lds_v6"
    }
```

❌ **NEVER proceed if you see:**
```
# module.aks.azurerm_kubernetes_cluster.aks must be replaced
# module.aks.azurerm_kubernetes_cluster.aks will be destroyed
```

### Safety Checklist

- [ ] Verified `prevent_destroy = true` is in the lifecycle block
- [ ] Verified `temporary_name_for_rotation` is configured
- [ ] Ran `tofu plan` and confirmed "will be updated in-place"
- [ ] Scheduled during a maintenance window
- [ ] Notified application owners
- [ ] Have rollback plan ready

## Step-by-Step Upgrade Process

### 1. Update Configuration

**For default node pool (system pool):**
```hcl
# In environments/dpn_infrastructure.tfvars
aks_vm_size = "Standard_D4lds_v6"  # Change from D2lds_v6
```

**For workload node pool:**
```hcl
workload_node_pool_vm_size = "Standard_D4lds_v6"
```

### 2. Run OpenTofu Plan

```bash
tofu plan -var-file=environments/dev.tfvars -out=tfplan
```

**Verify the output shows:**
- ✅ "will be updated in-place"
- ✅ Shows temporary_name_for_rotation being added
- ✅ NO "must be replaced" or "will be destroyed"

### 3. Review the Plan Carefully

**Look for:**
- How many resources will be changed?
- Are there any unexpected replacements?
- Does it show node pool rotation logic?

**DO NOT PROCEED if:**
- The cluster shows as "must be replaced"
- The entire default_node_pool shows as replaced
- You see warnings about data loss

### 4. Apply the Changes

```bash
tofu apply tfplan
```

### 5. Monitor the Process

**Watch the Azure Portal:**
1. Navigate to: AKS Cluster → Node pools
2. You should see:
   - New temp pool appears (e.g., "systemp" or "worktemp")
   - Temp pool becomes "Ready"
   - Old pool status changes to "Deleting"
   - Temp pool renamed to original name

**Expected Timeline:**
- Temp pool creation: 5-7 minutes
- Workload drain: 2-5 minutes (depends on pod count)
- Old pool deletion: 2-3 minutes
- Total: ~10-15 minutes

## What Can Go Wrong

### Issue: Cluster Gets Destroyed Instead of Updated

**Cause:** Certain property changes force cluster replacement
**Prevention:** 
- Always run plan first
- Use `prevent_destroy = true` (already configured)
- Never change immutable properties

**Immutable Properties (force replacement):**
- `name`
- `dns_prefix_private_cluster`
- `private_dns_zone_id`
- `network_profile.network_plugin`

### Issue: Temporary Pool Not Created

**Cause:** `temporary_name_for_rotation` missing or invalid
**Solution:** Verify it's set in the default_node_pool and workload node pool configs

### Issue: Pod Eviction Failures

**Cause:** Pods with PodDisruptionBudgets or lacking proper probes
**Solution:** Ensure apps have:
- Proper liveness/readiness probes
- PodDisruptionBudgets allowing at least 1 unavailable
- Multiple replicas for high availability

## Configuration Reference

### Default Node Pool
```hcl
default_node_pool {
  name                        = "system"
  vm_size                     = var.vm_size
  temporary_name_for_rotation = "systemp"  # ← REQUIRED for SKU changes
  
  upgrade_settings {
    max_surge                     = "10%"
    drain_timeout_in_minutes      = 30
    node_soak_duration_in_minutes = 0
  }
}
```

### Workload Node Pool
```hcl
resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  name                        = "workload"
  vm_size                     = var.workload_node_pool_vm_size
  temporary_name_for_rotation = "worktemp"  # ← REQUIRED for SKU changes
  
  upgrade_settings {
    max_surge                     = "10%"
    drain_timeout_in_minutes      = 30
    node_soak_duration_in_minutes = 0
  }
}
```

## Rollback Procedure

If the upgrade fails or causes issues:

1. **Stop the OpenTofu apply** (if still running)
2. **Revert the configuration:**
   ```bash
   git revert <commit-sha>
   ```
3. **Run plan and verify:**
   ```bash
   tofu plan -var-file=environments/dev.tfvars
   ```
4. **Apply the rollback:**
   ```bash
   tofu apply -var-file=environments/dev.tfvars
   ```

## Testing Recommendations

**Before production:**
1. Test in DPN-001 (development) first
2. Deploy a sample application
3. Verify the upgrade process works correctly
4. Only then proceed with DPN-001

**During upgrade:**
1. Monitor application health
2. Check pod status: `kubectl get pods -A`
3. Watch events: `kubectl get events -A --sort-by='.lastTimestamp'`
4. Monitor node status: `kubectl get nodes -w`

## Additional Resources

- [Azure AKS Best Practices](https://learn.microsoft.com/azure/aks/best-practices)
- [AKS Node Pool Upgrade](https://learn.microsoft.com/azure/aks/manage-node-pools)
- [OpenTofu AzureRM Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster)

## Questions?

Contact the infrastructure team before making changes to production clusters.
