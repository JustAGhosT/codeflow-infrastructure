#!/bin/bash
# Script to deploy Static Web App infrastructure
# Creates resource group if it doesn't exist, then deploys the Static Web App

set -e

ENVIRONMENT=${1:-prod}
REGION_ABBR=${2:-san}
LOCATION=${3:-"eastus2"}
RESOURCE_GROUP="${ENVIRONMENT}-rg-${REGION_ABBR}-codeflow"

echo "Deploying Static Web App infrastructure..."
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION_ABBR"
echo "Location: $LOCATION"
echo "Resource Group: $RESOURCE_GROUP"

# Create resource group if it doesn't exist
echo "Creating resource group if it doesn't exist..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none

# Deploy the Static Web App
echo "Deploying Static Web App..."
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file infrastructure/bicep/website.bicep \
  --parameters \
    environment="$ENVIRONMENT" \
    regionAbbr="$REGION_ABBR" \
    location="$LOCATION" \
    customDomain="codeflow.io"

echo "Deployment complete!"
echo "Static Web App name: ${ENVIRONMENT}-stapp-${REGION_ABBR}-codeflow"

