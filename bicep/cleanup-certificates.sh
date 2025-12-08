#!/bin/bash
# Cleanup duplicate managed certificates before Azure Container Apps deployment
# This script removes existing managed certificates for a domain to prevent
# "DuplicateManagedCertificateInEnvironment" errors during deployment

set -e

# Configuration - update these values for your deployment
RESOURCE_GROUP="${RESOURCE_GROUP:-prod-rg-san-autopr}"
ENV_NAME="${ENV_NAME:-prod-autopr-san-env}"
CUSTOM_DOMAIN="${CUSTOM_DOMAIN:-app.autopr.io}"

echo "=============================================="
echo "Azure Container Apps Certificate Cleanup"
echo "=============================================="
echo "Resource Group: $RESOURCE_GROUP"
echo "Environment: $ENV_NAME"
echo "Domain: $CUSTOM_DOMAIN"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Error: Azure CLI is not installed"
    echo "Please install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    echo "❌ Error: Not logged in to Azure"
    echo "Please run: az login"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "⚠️ Warning: jq is not installed. Using alternative parsing method."
    USE_JQ=false
else
    USE_JQ=true
fi

# Check if environment exists
echo "🔍 Checking if environment exists..."
if ! az containerapp env show -n "$ENV_NAME" -g "$RESOURCE_GROUP" &>/dev/null; then
    echo "ℹ️ Environment '$ENV_NAME' does not exist yet"
    echo "No certificates to clean up. You can proceed with deployment."
    exit 0
fi

echo "✅ Environment exists, checking for managed certificates..."
echo ""

# List all certificates
CERTS_OUTPUT=$(az containerapp env certificate list \
  --name "$ENV_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --output json 2>/dev/null || echo "[]")

if [ "$CERTS_OUTPUT" == "[]" ]; then
    echo "ℹ️ No certificates found in environment"
    echo "You can proceed with deployment."
    exit 0
fi

# Find certificates for our domain
if [ "$USE_JQ" = true ]; then
    DUPLICATE_CERTS=$(echo "$CERTS_OUTPUT" | jq -r \
      --arg domain "$CUSTOM_DOMAIN" \
      '.[] | select(.properties.subjectName == $domain and .type == "Microsoft.App/managedEnvironments/managedCertificates") | .name')
else
    # Alternative parsing without jq (less reliable but works in constrained environments)
    # WARNING: This will get ALL certificate names, but CANNOT filter by domain
    DUPLICATE_CERTS=$(echo "$CERTS_OUTPUT" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$DUPLICATE_CERTS" ]; then
        echo "⚠️  WARNING: jq is not available - cannot automatically filter certificates by domain!"
        echo "    All certificates in the environment will be listed."
        echo "    You MUST manually verify they are for domain: $CUSTOM_DOMAIN"
        echo "    Installing jq is recommended for safer operation: https://stedolan.github.io/jq/download/"
        echo ""
    fi
fi

if [ -z "$DUPLICATE_CERTS" ] || [ "$DUPLICATE_CERTS" == "null" ]; then
    echo "✅ No duplicate managed certificates found for domain: $CUSTOM_DOMAIN"
    echo "You can proceed with deployment."
    exit 0
fi

# Display found certificates
echo "⚠️ Found duplicate managed certificate(s) for domain: $CUSTOM_DOMAIN"
echo ""
echo "Certificates to be deleted:"
echo "$DUPLICATE_CERTS" | while IFS= read -r cert_name; do
    if [ -n "$cert_name" ]; then
        echo "  - $cert_name"
    fi
done
echo ""

# Ask for confirmation (skip in CI/CD)
if [ -t 0 ] && [ "$CI" != "true" ]; then
    read -p "Do you want to delete these certificates? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Cleanup cancelled by user"
        exit 1
    fi
fi

# Delete certificates
echo "🗑️ Deleting duplicate certificates..."
echo ""

DELETED_COUNT=0
FAILED_COUNT=0

while IFS= read -r cert_name; do
    if [ -n "$cert_name" ]; then
        echo "Deleting certificate: $cert_name"
        if az containerapp env certificate delete \
            --name "$ENV_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --certificate "$cert_name" \
            --yes 2>/dev/null; then
            echo "  ✅ Deleted successfully"
            DELETED_COUNT=$((DELETED_COUNT + 1))
        else
            echo "  ⚠️ Failed to delete (may not exist or be in use)"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
        echo ""
    fi
done < <(echo "$DUPLICATE_CERTS")

echo "=============================================="
echo "Cleanup Summary"
echo "=============================================="
if [ $FAILED_COUNT -eq 0 ]; then
    echo "✅ All duplicate certificates removed successfully"
    echo "You can now proceed with your deployment."
else
    echo "⚠️ Some certificates could not be deleted"
    echo "This may happen if certificates are currently bound to container apps."
    echo "Try removing the custom domain from the container app first, then run this script again."
fi
echo ""
