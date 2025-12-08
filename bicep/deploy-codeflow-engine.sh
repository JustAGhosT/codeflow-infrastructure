#!/bin/bash
# Script to deploy AutoPR Engine infrastructure
# Creates resource group if it doesn't exist, then deploys the infrastructure

set -e

ENVIRONMENT=${1:-prod}
REGION_ABBR=${2:-san}
LOCATION=${3:-"eastus2"}
POSTGRES_LOCATION=${4:-"southafricanorth"}
CONTAINER_IMAGE=${5:-""}
CUSTOM_DOMAIN=${6:-"app.autopr.io"}
RESOURCE_GROUP="prod-rg-${REGION_ABBR}-autopr"

# Use placeholder if no image specified
if [ -z "$CONTAINER_IMAGE" ]; then
  echo "⚠️  WARNING: No container image specified. Using placeholder image for testing."
  echo "   Build and push the image first, then update the Container App."
  echo "   See: bicep/BUILD_AND_PUSH_IMAGE.md"
  echo ""
  CONTAINER_IMAGE="mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
fi

echo "Deploying AutoPR Engine infrastructure..."
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION_ABBR"
echo "Location: $LOCATION"
echo "Custom Domain: $CUSTOM_DOMAIN"
echo "Resource Group: $RESOURCE_GROUP"

# Check if resource group exists, create if not
if ! az group show --name "$RESOURCE_GROUP" &>/dev/null; then
  echo "Creating resource group..."
  az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output none
else
  echo "Resource group already exists."
fi

# Cleanup duplicate certificates to prevent deployment failures
ENV_NAME="${ENVIRONMENT}-autopr-${REGION_ABBR}-env"
echo ""
echo "Checking for duplicate managed certificates..."
if az containerapp env show -n "$ENV_NAME" -g "$RESOURCE_GROUP" &>/dev/null; then
  CERT_COUNT=$(az containerapp env certificate list \
    --name "$ENV_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "length([?properties.subjectName=='$CUSTOM_DOMAIN' && type=='Microsoft.App/managedEnvironments/managedCertificates'])" \
    --output tsv 2>/dev/null || echo "0")
  
  if [ "$CERT_COUNT" -gt 0 ]; then
    echo "⚠️  Found $CERT_COUNT existing certificate(s) for domain $CUSTOM_DOMAIN"
    echo "Cleaning up to prevent DuplicateManagedCertificateInEnvironment error..."
    
    # Run the cleanup script using path relative to this script's location
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    bash "$SCRIPT_DIR/cleanup-certificates.sh"
    echo ""
  else
    echo "✅ No duplicate certificates found"
  fi
else
  echo "ℹ️  Environment does not exist yet, skipping certificate cleanup"
fi
echo ""

# Generate passwords if not provided
if [ -z "$POSTGRES_LOGIN" ]; then
  echo "Using default PostgreSQL login..."
  POSTGRES_LOGIN="autopr"
fi

if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "Generating PostgreSQL password..."
  POSTGRES_PASSWORD=$(openssl rand -base64 32)
fi

if [ -z "$REDIS_PASSWORD" ]; then
  echo "Generating Redis password..."
  REDIS_PASSWORD=$(openssl rand -base64 32)
fi

# Save credentials securely before deployment
CREDENTIALS_FILE=".credentials-${RESOURCE_GROUP}.json"
cat > "$CREDENTIALS_FILE" << CREDS_EOF
{
  "resource_group": "$RESOURCE_GROUP",
  "postgres_login": "$POSTGRES_LOGIN",
  "postgres_password": "$POSTGRES_PASSWORD",
  "redis_password": "$REDIS_PASSWORD",
  "created_at": "$(date -Iseconds)"
}
CREDS_EOF
chmod 600 "$CREDENTIALS_FILE"

# Deploy the infrastructure
echo "Deploying infrastructure..."
az deployment group create \
  --name autopr-engine \
  --resource-group "$RESOURCE_GROUP" \
  --template-file bicep/autopr-engine.bicep \
  --parameters \
    environment="$ENVIRONMENT" \
    regionAbbr="$REGION_ABBR" \
    location="$LOCATION" \
    postgresLocation="$POSTGRES_LOCATION" \
    customDomain="$CUSTOM_DOMAIN" \
    containerImage="$CONTAINER_IMAGE" \
    postgresLogin="$POSTGRES_LOGIN" \
    postgresPassword="$POSTGRES_PASSWORD" \
    redisPassword="$REDIS_PASSWORD" \
  --output json > deployment-output.json

echo "Deployment complete!"
echo ""
echo "⚠️  IMPORTANT: Credentials saved to $CREDENTIALS_FILE"
echo "   Store them in a secure secrets manager (Azure Key Vault, etc.)"
echo "   Then delete the file: rm $CREDENTIALS_FILE"
echo "   DO NOT commit credentials files to version control!"
echo ""
echo "Container App URL:"
jq -r '.properties.outputs.containerAppUrl.value' deployment-output.json
echo ""
echo "Custom Domain: $CUSTOM_DOMAIN"
echo ""
echo "Next steps:"
echo "1. Add DNS CNAME record for $CUSTOM_DOMAIN pointing to the Container App URL above"
echo "2. Wait for DNS propagation (typically 15-30 minutes)"
echo "3. Azure will automatically provision the SSL certificate"

