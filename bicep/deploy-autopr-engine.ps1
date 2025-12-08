# Script to deploy AutoPR Engine infrastructure
# Creates resource group if it doesn't exist, then deploys the infrastructure

param(
    [string]$Environment = "prod",
    [string]$RegionAbbr = "san",
    [string]$Location = "eastus2",
    [string]$PostgresLocation = "southafricanorth",
    [string]$ContainerImage = "",
    [string]$CustomDomain = "app.autopr.io"
)

$ErrorActionPreference = "Stop"

$ResourceGroup = "prod-rg-${RegionAbbr}-autopr"

Write-Host "Deploying AutoPR Engine infrastructure..."
Write-Host "Environment: $Environment"
Write-Host "Region: $RegionAbbr"
Write-Host "Location: $Location"
Write-Host "PostgreSQL Location: $PostgresLocation"
Write-Host "Resource Group: $ResourceGroup"
Write-Host ""

# Check if resource group exists, create if not
$rgExists = az group show --name $ResourceGroup 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating resource group..."
    az group create --name $ResourceGroup --location $Location --output none
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create resource group"
        exit 1
    }
} else {
    Write-Host "Resource group already exists."
}

# Cleanup duplicate certificates to prevent deployment failures
$EnvName = "$Environment-autopr-$RegionAbbr-env"

Write-Host ""
Write-Host "Checking for duplicate managed certificates..."
$envExists = az containerapp env show -n $EnvName -g $ResourceGroup 2>&1
if ($LASTEXITCODE -eq 0) {
    $certs = az containerapp env certificate list `
        --name $EnvName `
        --resource-group $ResourceGroup `
        --output json 2>$null | ConvertFrom-Json
    
    $duplicateCerts = $certs | Where-Object { 
        $_.properties.subjectName -eq $CustomDomain -and 
        $_.type -eq "Microsoft.App/managedEnvironments/managedCertificates" 
    }
    
    if ($duplicateCerts) {
        Write-Host "⚠️  Found $($duplicateCerts.Count) existing certificate(s) for domain $CustomDomain" -ForegroundColor Yellow
        Write-Host "Cleaning up to prevent DuplicateManagedCertificateInEnvironment error..."
        
        foreach ($cert in $duplicateCerts) {
            Write-Host "Deleting certificate: $($cert.name)"
            az containerapp env certificate delete `
                --name $EnvName `
                --resource-group $ResourceGroup `
                --certificate $cert.name `
                --yes 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  ⚠️  Failed to delete certificate (may not exist or be in use)" -ForegroundColor Yellow
            } else {
                Write-Host "  ✅ Deleted successfully" -ForegroundColor Green
            }
        }
        Write-Host "✅ Cleanup completed" -ForegroundColor Green
    } else {
        Write-Host "✅ No duplicate certificates found" -ForegroundColor Green
    }
} else {
    Write-Host "ℹ️  Environment does not exist yet, skipping certificate cleanup"
}
Write-Host ""

# Generate passwords if not provided
if (-not $env:POSTGRES_PASSWORD) {
    Write-Host "Generating PostgreSQL password..."
    $env:POSTGRES_PASSWORD = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
}

if (-not $env:REDIS_PASSWORD) {
    Write-Host "Generating Redis password..."
    $env:REDIS_PASSWORD = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
}

# Get container image from parameter or default
if ([string]::IsNullOrEmpty($ContainerImage)) {
    Write-Host "⚠️  WARNING: No container image specified. Using placeholder image for testing." -ForegroundColor Yellow
    Write-Host "   Build and push the image first, then update the Container App." -ForegroundColor Yellow
    Write-Host "   See: infrastructure/bicep/BUILD_AND_PUSH_IMAGE.md" -ForegroundColor Yellow
    Write-Host ""
    $ContainerImage = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

# Deploy the infrastructure
Write-Host "Deploying infrastructure..."
Write-Host "Container Image: $ContainerImage"
Write-Host ""

az deployment group create `
    --name autopr-engine `
    --resource-group $ResourceGroup `
    --template-file infrastructure/bicep/autopr-engine.bicep `
    --parameters `
        environment=$Environment `
        regionAbbr=$RegionAbbr `
        location=$Location `
        postgresLocation=$PostgresLocation `
        customDomain=$CustomDomain `
        containerImage=$ContainerImage `
        postgresPassword="$env:POSTGRES_PASSWORD" `
        redisPassword="$env:REDIS_PASSWORD" `
    --output json | Out-File -FilePath deployment-output.json -Encoding utf8

if ($LASTEXITCODE -ne 0) {
    Write-Error "Deployment failed"
    exit 1
}

Write-Host ""
Write-Host "Deployment complete!"
Write-Host "PostgreSQL password: $env:POSTGRES_PASSWORD"
Write-Host "Redis password: $env:REDIS_PASSWORD"
Write-Host ""
Write-Host "⚠️  IMPORTANT: Save these passwords securely!"
Write-Host ""

# Get container app URL
$outputs = Get-Content deployment-output.json | ConvertFrom-Json
$containerAppUrl = $outputs.properties.outputs.containerAppUrl.value
Write-Host "Container App URL: $containerAppUrl"

