# Cleanup duplicate managed certificates before Azure Container Apps deployment
# This script removes existing managed certificates for a domain to prevent
# "DuplicateManagedCertificateInEnvironment" errors during deployment

param(
    [string]$ResourceGroup = "prod-rg-san-autopr",
    [string]$EnvironmentName = "prod-autopr-san-env",
    [string]$CustomDomain = "app.autopr.io"
)

$ErrorActionPreference = "Stop"

Write-Host "=============================================="
Write-Host "Azure Container Apps Certificate Cleanup"
Write-Host "=============================================="
Write-Host "Resource Group: $ResourceGroup"
Write-Host "Environment: $EnvironmentName"
Write-Host "Domain: $CustomDomain"
Write-Host ""

# Check if Azure CLI is installed
$azVersion = az version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Azure CLI is not installed. Please install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Check if user is logged in
$account = az account show 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Not logged in to Azure. Please run: az login"
    exit 1
}

# Check if environment exists
Write-Host "🔍 Checking if environment exists..."
$envExists = az containerapp env show -n $EnvironmentName -g $ResourceGroup 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ℹ️ Environment '$EnvironmentName' does not exist yet"
    Write-Host "No certificates to clean up. You can proceed with deployment."
    exit 0
}

Write-Host "✅ Environment exists, checking for managed certificates..."
Write-Host ""

# List all certificates
$certsJson = az containerapp env certificate list `
    --name $EnvironmentName `
    --resource-group $ResourceGroup `
    --output json 2>$null

if (-not $certsJson -or $certsJson -eq "[]") {
    Write-Host "ℹ️ No certificates found in environment"
    Write-Host "You can proceed with deployment."
    exit 0
}

# Parse certificates and find duplicates for our domain
try {
    $certs = $certsJson | ConvertFrom-Json
    $duplicateCerts = $certs | Where-Object { 
        $_.properties.subjectName -eq $CustomDomain -and 
        $_.type -eq "Microsoft.App/managedEnvironments/managedCertificates" 
    }
} catch {
    Write-Error "Failed to parse certificate list: $_"
    exit 1
}

if (-not $duplicateCerts -or $duplicateCerts.Count -eq 0) {
    Write-Host "✅ No duplicate managed certificates found for domain: $CustomDomain"
    Write-Host "You can proceed with deployment."
    exit 0
}

# Display found certificates
Write-Host "⚠️ Found duplicate managed certificate(s) for domain: $CustomDomain" -ForegroundColor Yellow
Write-Host ""
Write-Host "Certificates to be deleted:"
foreach ($cert in $duplicateCerts) {
    Write-Host "  - $($cert.name)"
}
Write-Host ""

# Ask for confirmation (skip in CI/CD)
$isInteractive = [Environment]::UserInteractive -and -not $env:CI
if ($isInteractive) {
    $confirm = Read-Host "Do you want to delete these certificates? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "❌ Cleanup cancelled by user"
        exit 1
    }
}

# Delete certificates
Write-Host "🗑️ Deleting duplicate certificates..."
Write-Host ""

$deletedCount = 0
$failedCount = 0

foreach ($cert in $duplicateCerts) {
    Write-Host "Deleting certificate: $($cert.name)"
    
    $result = az containerapp env certificate delete `
        --name $EnvironmentName `
        --resource-group $ResourceGroup `
        --certificate $cert.name `
        --yes 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Deleted successfully" -ForegroundColor Green
        $deletedCount++
    } else {
        Write-Host "  ⚠️ Failed to delete (may not exist or be in use)" -ForegroundColor Yellow
        $failedCount++
    }
    Write-Host ""
}

Write-Host "=============================================="
Write-Host "Cleanup Summary"
Write-Host "=============================================="
if ($failedCount -eq 0) {
    Write-Host "✅ All duplicate certificates removed successfully" -ForegroundColor Green
    Write-Host "You can now proceed with your deployment."
} else {
    Write-Host "⚠️ Some certificates could not be deleted" -ForegroundColor Yellow
    Write-Host "This may happen if certificates are currently bound to container apps."
    Write-Host "Try removing the custom domain from the container app first, then run this script again."
}
Write-Host ""
