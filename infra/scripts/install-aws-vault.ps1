<#
install-aws-vault.ps1
Downloads the latest aws-vault Windows amd64 executable into $env:USERPROFILE\bin and adds it to PATH for the current session.
Run this script locally in a PowerShell session (it will not run here if outbound HTTP is blocked).

Usage:
  powershell -ExecutionPolicy Bypass -File .\infra\scripts\install-aws-vault.ps1
#>
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$false)]
  [string]$Tag
)

try {
    $ErrorActionPreference = 'Stop'
  if ($Tag) {
    Write-Host "Querying aws-vault release for tag $Tag..."
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/99designs/aws-vault/releases/tags/$Tag" -UseBasicParsing
  }
  else {
    Write-Host "Querying latest aws-vault release from GitHub..."
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/99designs/aws-vault/releases/latest' -UseBasicParsing
  }

  $asset = $release.assets | Where-Object { $_.name -match 'windows.*amd64|windows.*x86_64|windows.*x64' } | Select-Object -First 1
  if (-not $asset) { throw "No windows amd64 asset found in release (checked assets: $($release.assets | ForEach-Object { $_.name } -join ', '))." }

  $downloadUrl = $asset.browser_download_url
    $destDir = Join-Path $env:USERPROFILE 'bin'
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    $dest = Join-Path $destDir 'aws-vault.exe'

    Write-Host "Downloading $($asset.name) to $dest"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $dest

    # Add to PATH for this session
    $env:PATH = "$destDir;$env:PATH"

    Write-Host "Downloaded to $dest" -ForegroundColor Green
    Write-Host "Verifying aws-vault version:" -ForegroundColor Cyan
    & "$dest" --version
    Write-Host "Installation complete. To persist PATH, add $destDir to your User PATH environment variable." -ForegroundColor Green
}
catch {
  # Write a clearer error message and avoid passing complex objects directly to Write-Error
  if ($_.Exception) {
    Write-Error ("Install failed: {0}" -f $_.Exception.ToString())
  }
  else {
    Write-Error ("Install failed: {0}" -f $_.ToString())
  }
  exit 1
}
