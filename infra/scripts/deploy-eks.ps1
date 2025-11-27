<#
PowerShell helper: terraform init -> plan -> apply for infra/ directory

Usage: run in repository root or with working directory set to infra/.

Prerequisites:
- terraform installed and in PATH
- aws cli and credentials configured (profile matches infra/terraform.tfvars aws_profile)
- (recommended) use aws-vault to manage credentials

This script will run a `terraform plan` and then prompt before `terraform apply`.
#>

param(
    [switch]$AutoApprove
)

Set-Location -Path (Join-Path $PSScriptRoot "..")
Write-Host "Working from: $(Get-Location)"

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Error "terraform not found in PATH. Install terraform and try again."
    exit 1
}

Push-Location infra
try {
    terraform init -input=false
    terraform plan -out=tfplan -input=false

    if ($AutoApprove) {
        terraform apply -input=false -auto-approve tfplan
    } else {
        Write-Host ''
        Write-Host "Terraform plan created at ./tfplan" -ForegroundColor Yellow
        $ok = Read-Host "Proceed to apply the plan? (yes/no)"
        if ($ok -in @('y','Y','yes','Yes')) {
            terraform apply -input=false tfplan
        } else {
            Write-Host "Aborting without apply. Inspect tfplan if needed." -ForegroundColor Cyan
        }
    }
}
finally {
    Pop-Location
}
