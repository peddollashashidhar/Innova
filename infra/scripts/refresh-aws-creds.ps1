<#
PowerShell helper: refresh-aws-creds.ps1
Usage:
  - Mode: 'aws-vault' or 'sso'
  - Profile: profile name for aws-vault or AWS CLI SSO profile
  - TerraformArgs: array of terraform arguments (default: plan)

Examples:
  .\refresh-aws-creds.ps1 -Mode aws-vault -Profile my-aws-profile -TerraformArgs plan
  .\refresh-aws-creds.ps1 -Mode sso -Profile innova-sso -TerraformArgs @('plan','-out=plan.out')

This script runs in the repository and executes terraform commands using temporary credentials.
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('aws-vault','sso')]
    [string]$Mode,

    [Parameter(Mandatory=$true)]
    [string]$Profile,

    [Parameter(Mandatory=$false)]
    [string[]]$TerraformArgs = @('plan')
)

function Run-Terraform {
    param([string[]]$Args)
    $repoRoot = Resolve-Path -Path "$PSScriptRoot\.." -ErrorAction Stop
    Set-Location -Path $repoRoot
    Write-Host "-- Running: terraform $($Args -join ' ')" -ForegroundColor Cyan
    $proc = Start-Process -FilePath "terraform" -ArgumentList $Args -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        Write-Error "terraform exited with code $($proc.ExitCode)"
        exit $proc.ExitCode
    }
}

try {
    if ($Mode -eq 'aws-vault') {
        if (-not (Get-Command aws-vault -ErrorAction SilentlyContinue)) {
            Write-Error "aws-vault not found in PATH. Install it (choco install aws-vault) or adjust PATH."; exit 2
        }
        # Build argument list for aws-vault exec <profile> -- terraform <args>
        $args = @('exec', $Profile, '--', 'terraform') + $TerraformArgs
        Write-Host "-- Executing: aws-vault $($args -join ' ')" -ForegroundColor Green
        & aws-vault @args
        if ($LASTEXITCODE -ne 0) { throw "aws-vault exec failed with exit code $LASTEXITCODE" }
    }
    else {
        # SSO flow
        if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
            Write-Error "AWS CLI not found in PATH. Install AWS CLI v2 and configure SSO (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)"; exit 2
        }
        Write-Host "-- Running: aws sso login --profile $Profile" -ForegroundColor Green
        & aws sso login --profile $Profile
        if ($LASTEXITCODE -ne 0) { throw "aws sso login failed with exit code $LASTEXITCODE" }
        # Set profile env for terraform
        $env:AWS_PROFILE = $Profile
        Run-Terraform -Args $TerraformArgs
    }
}
catch {
    Write-Error "Error: $_"
    exit 10
}
