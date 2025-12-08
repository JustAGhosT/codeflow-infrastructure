#!/bin/bash
# Script to clean up AutoPR Engine infrastructure resources

set -e

RESOURCE_GROUP=${1:-"prod-rg-san-autopr"}

echo "Cleaning up AutoPR Engine resources in resource group: $RESOURCE_GROUP"
echo ""
echo "⚠️  WARNING: This will delete all resources in the resource group!"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

echo ""
echo "Deleting resources..."

# Delete resources by type
echo "Deleting Container Apps..."
az containerapp list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv | while read name; do
  if [ -n "$name" ]; then
    echo "  Deleting: $name"
    az containerapp delete --name "$name" --resource-group "$RESOURCE_GROUP" --yes || true
  fi
done

echo "Deleting Container App Environments..."
az containerapp env list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv | while read name; do
  if [ -n "$name" ]; then
    echo "  Deleting: $name"
    az containerapp env delete --name "$name" --resource-group "$RESOURCE_GROUP" --yes || true
  fi
done

echo "Deleting PostgreSQL servers..."
az postgres flexible-server list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv | while read name; do
  if [ -n "$name" ]; then
    echo "  Deleting: $name"
    az postgres flexible-server delete --name "$name" --resource-group "$RESOURCE_GROUP" --yes || true
  fi
done

echo "Deleting Redis caches..."
az redis list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv | while read name; do
  if [ -n "$name" ]; then
    echo "  Deleting: $name"
    az redis delete --name "$name" --resource-group "$RESOURCE_GROUP" --yes || true
  fi
done

echo "Deleting Log Analytics workspaces..."
az monitor log-analytics workspace list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv | while read name; do
  if [ -n "$name" ]; then
    echo "  Deleting: $name"
    az monitor log-analytics workspace delete --workspace-name "$name" --resource-group "$RESOURCE_GROUP" --yes || true
  fi
done

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Note: Some resources may take a few minutes to fully delete."
echo "You can verify with: az resource list --resource-group $RESOURCE_GROUP"

