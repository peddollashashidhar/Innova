Set-Location -Path (Join-Path $PSScriptRoot "..")
Write-Host "Working from: $(Get-Location)"

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Error "terraform not found in PATH. Install terraform and try again."
    exit 1
}

Push-Location infra
try {
    Write-Host "This will destroy all resources managed by the infra Terraform root in infra/." -ForegroundColor Yellow
    $ok = Read-Host "Proceed to destroy? (yes/no)"
    if ($ok -in @('y','Y','yes','Yes')) {
        terraform init -input=false
        terraform destroy -auto-approve
    } else {
        Write-Host "Aborting destroy" -ForegroundColor Cyan
    }
}
finally {
    Pop-Location
}
