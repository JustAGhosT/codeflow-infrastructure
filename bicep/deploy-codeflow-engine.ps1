<#
.SYNOPSIS
Deploys CodeFlow Engine infrastructure to Azure.

.DESCRIPTION
Creates Container Apps Environment, Container App, PostgreSQL Database, and Redis Cache.

.PARAMETER Environment
Environment name (dev, test, uat, prod). Default: dev

.PARAMETER RegionAbbr
Azure region abbreviation (san, eus, wus, etc.). Default: san

.PARAMETER Location
Azure location for most resources. Default: southafricanorth

.PARAMETER PostgresLocation
Azure location for PostgreSQL (must support Flexible Server). Default: southafricanorth

.PARAMETER ContainerImage
Container image name. Default: placeholder image

.PARAMETER CustomDomain
Custom domain name for the container app. Default: app.codeflow.io

.PARAMETER OrgCode
Organization code. Default: nl

.PARAMETER Project
Project name. Default: codeflow

.EXAMPLE
.\deploy-codeflow-engine.ps1 -Environment dev -RegionAbbr san -Location southafricanorth
#>

[CmdletBinding()]
param(
    [string]$Environment = "dev",
    [string]$RegionAbbr = "san",
    [string]$Location = "southafricanorth",
    [string]$PostgresLocation = "southafricanorth",
    [string]$ContainerImage = "",
    [string]$CustomDomain = "app.codeflow.io",
    [string]$OrgCode = "nl",
    [string]$Project = "codeflow"
)

$ErrorActionPreference = 'Stop'

$ResourceGroup = "$OrgCode-$Environment-$Project-rg-$RegionAbbr"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying CodeFlow Engine Infrastructure" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Environment: $Environment" -ForegroundColor White
Write-Host "  Region: $RegionAbbr" -ForegroundColor White
Write-Host "  Location: $Location" -ForegroundColor White
Write-Host "  PostgreSQL Location: $PostgresLocation" -ForegroundColor White
Write-Host "  Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "  Custom Domain: $CustomDomain" -ForegroundColor White
Write-Host ""

# Check if resource group exists
Write-Host "Checking resource group..." -ForegroundColor Yellow
$rgExists = az group show --name $ResourceGroup --query "name" --output tsv 2>$null
if (-not $rgExists) {
    Write-Host "  Creating resource group..." -ForegroundColor Gray
    az group create --name $ResourceGroup --location $Location --output none
    Write-Host "  ✓ Resource group created" -ForegroundColor Green
} else {
    Write-Host "  ✓ Resource group already exists" -ForegroundColor Green
}
Write-Host ""

# Use placeholder if no image specified
if ([string]::IsNullOrEmpty($ContainerImage)) {
    Write-Host "⚠️  WARNING: No container image specified. Using placeholder image for testing." -ForegroundColor Yellow
    Write-Host "   Build and push the image first, then update the Container App." -ForegroundColor Gray
    Write-Host "   See: bicep/BUILD_AND_PUSH_IMAGE.md" -ForegroundColor Gray
    Write-Host ""
    $ContainerImage = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

# Generate passwords if not provided
if ([string]::IsNullOrEmpty($env:POSTGRES_PASSWORD)) {
    Write-Host "Generating PostgreSQL password..." -ForegroundColor Yellow
    $env:POSTGRES_PASSWORD = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
}

if ([string]::IsNullOrEmpty($env:REDIS_PASSWORD)) {
    Write-Host "Generating Redis password..." -ForegroundColor Yellow
    $env:REDIS_PASSWORD = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
}

$PostgresLogin = "codeflow"

# Save credentials securely
$CredentialsFile = ".credentials-$ResourceGroup.json"
$credentials = @{
    resource_group = $ResourceGroup
    postgres_login = $PostgresLogin
    postgres_password = $env:POSTGRES_PASSWORD
    redis_password = $env:REDIS_PASSWORD
    created_at = (Get-Date -Format "o")
} | ConvertTo-Json

$credentials | Out-File -FilePath $CredentialsFile -Encoding utf8 -NoNewline
$file = Get-Item $CredentialsFile
$file.Attributes = $file.Attributes -bor [System.IO.FileAttributes]::Hidden

Write-Host "⚠️  IMPORTANT: Credentials saved to $CredentialsFile" -ForegroundColor Yellow
Write-Host "   Store them in a secure secrets manager (Azure Key Vault, etc.)" -ForegroundColor Gray
Write-Host "   Then delete the file: Remove-Item $CredentialsFile" -ForegroundColor Gray
Write-Host "   DO NOT commit credentials files to version control!" -ForegroundColor Red
Write-Host ""

# Deploy the infrastructure
Write-Host "Deploying infrastructure..." -ForegroundColor Green
$deploymentName = "codeflow-engine-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

$bicepFile = Join-Path $PSScriptRoot "codeflow-engine.bicep"

az deployment group create `
    --name $deploymentName `
    --resource-group $ResourceGroup `
    --template-file $bicepFile `
    --parameters `
        environment=$Environment `
        regionAbbr=$RegionAbbr `
        location=$Location `
        postgresLocation=$PostgresLocation `
        customDomain=$CustomDomain `
        containerImage=$ContainerImage `
        postgresLogin=$PostgresLogin `
        postgresPassword=$env:POSTGRES_PASSWORD `
        redisPassword=$env:REDIS_PASSWORD `
    --output json | Out-File -FilePath "deployment-output.json" -Encoding utf8

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Deployment complete!" -ForegroundColor Green
    Write-Host ""
    
    # Get Container App URL
    $output = Get-Content "deployment-output.json" | ConvertFrom-Json
    $containerAppUrl = $output.properties.outputs.containerAppUrl.value
    
    Write-Host "Container App URL: $containerAppUrl" -ForegroundColor Cyan
    Write-Host "Custom Domain: $CustomDomain" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Add DNS CNAME record for $CustomDomain pointing to the Container App URL above" -ForegroundColor White
    Write-Host "2. Wait for DNS propagation (typically 15-30 minutes)" -ForegroundColor White
    Write-Host "3. Azure will automatically provision the SSL certificate" -ForegroundColor White
} else {
    Write-Host "✗ Deployment failed!" -ForegroundColor Red
    exit 1
}

