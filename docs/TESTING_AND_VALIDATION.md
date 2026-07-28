# Testing and Validation

This codebase has been validated as thoroughly as possible **without** deploying to a real Azure subscription. This page explains exactly what that means, what was checked, and how to run the same checks yourself - both before you deploy, and as part of your own CI if you want it.

## Why there's no "real" dry run included

`tofu plan` needs live Azure credentials and has to reach the actual Azure APIs - including for resources it isn't creating. Several modules use `data` sources to look up things assumed to already exist (your VNet, its subnets, your Log Analytics workspace), and those lookups happen even during `plan`. There's no way to produce a meaningful plan against placeholder values in the example `dpn_infrastructure.tfvars` (subscription ID `00000000-...`, example resource names) because those resources don't exist anywhere.

What *is* possible, and has been done, is exhaustive static validation - everything short of actually talking to Azure.

## What was checked

| Check | Tool | Result |
|---|---|---|
| HCL syntax, type consistency, resource/module references | `tofu validate` | Clean |
| Formatting | `tofu fmt -check -recursive` | Clean |
| Every required variable (no default) has a value in the example tfvars | Custom script comparing `variables.tf` against `dpn_infrastructure.tfvars` | 146/147 present - the 147th (`vm_admin_password`) is deliberately excluded (sensitive, supplied by the pipeline, never committed) |
| Deeper static lint (deprecated syntax, structural issues) across root + every module + bootstrap | `tflint` | Zero findings |
| Infrastructure misconfiguration scan, with the actual tfvars values applied | `trivy` (`--scanners misconfig`) | Zero findings |
| Compliance-mapped security scan | `checkov` | 79 passed, 14 documented exceptions (0 blocking) - see `.checkov.yaml` for the rationale behind every exception |
| GitHub Actions workflow schema/semantics | `actionlint` | Zero findings across all 4 workflow files |
| YAML syntax, all pipeline files (GitHub + Azure DevOps) | PyYAML | All parse cleanly |

None of this proves the code will succeed against a real subscription - only that nothing is structurally broken, every declared input is satisfied, and no known security misconfiguration is present in the default configuration.

## Running these checks yourself

```bash
cd dpn-azure-infrastructure

# Format + validate (no credentials needed)
tofu fmt -check -recursive
tofu init -backend=false
tofu validate

# tflint (no credentials needed)
tflint --config ../.tflint.hcl --recursive

# trivy (no credentials needed) - reads dpn_infrastructure.tfvars to resolve real values
trivy fs . --scanners misconfig --tf-vars environments/dpn_infrastructure.tfvars --ignorefile ../.trivyignore

# checkov (no credentials needed)
checkov -d . --framework terraform --config-file ../.checkov.yaml --var-file environments/dpn_infrastructure.tfvars --compact
```

None of the tools above are installed by the pipelines automatically (see the note in the root `README.md`) - install them yourself if you want to run this as part of your own quality gate.

## The one test that actually proves it works: a real deployment

If you have a sandbox/test Azure subscription available, the strongest validation is simply running the full bootstrap → plan → apply → verify → destroy cycle described in [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) against it before trusting this for a production DPN. Nothing in this repository requires a specific subscription or tenant - every value that's specific to your environment lives in `dpn_infrastructure.tfvars` and the pipeline secrets/variables, exactly as documented in [PREREQUISITES.md](PREREQUISITES.md).
