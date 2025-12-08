# Building and Pushing Container Image

Before deploying the AutoPR Engine infrastructure, you need to build and push the container image to a container registry.

## Option 1: Use GitHub Actions (Recommended)

The GitHub Actions workflow (`.github/workflows/deploy-codeflow-engine.yml`) will automatically build and push the image when you push to the `main` branch.

1. **Push your code to trigger the build:**
   ```bash
   git push origin main
   ```

2. **Wait for the build to complete** in GitHub Actions

3. **The image will be available at:**
   ```
   ghcr.io/justaghost/codeflow-engine:latest
   ```

## Option 2: Build and Push Manually

### Build the Image

```bash
# Build the Docker image
docker build -f docker/Dockerfile -t codeflow-engine:latest .

# Tag for GitHub Container Registry
docker tag codeflow-engine:latest ghcr.io/justaghost/codeflow-engine:latest
```

### Push to GitHub Container Registry

1. **Create a GitHub Personal Access Token** with `write:packages` permission:
   - Go to: https://github.com/settings/tokens
   - Create token with `write:packages` scope

2. **Login to GHCR:**
   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u JustAGhosT --password-stdin
   ```

3. **Push the image:**
   ```bash
   docker push ghcr.io/justaghost/codeflow-engine:latest
   ```

### Push to Azure Container Registry (Alternative)

If you prefer using Azure Container Registry:

1. **Login to ACR:**
   ```bash
   az acr login --name <your-acr-name>
   ```

2. **Tag and push:**
   ```bash
   docker tag codeflow-engine:latest <your-acr-name>.azurecr.io/codeflow-engine:latest
   docker push <your-acr-name>.azurecr.io/codeflow-engine:latest
   ```

3. **Update the deployment:**
   ```bash
   az deployment group create \
     --resource-group prod-rg-san-autopr \
     --template-file infrastructure/bicep/codeflow-engine.bicep \
     --parameters \
       containerImage="<your-acr-name>.azurecr.io/codeflow-engine:latest" \
       ...
   ```

## Option 3: Use a Placeholder Image (Testing Only)

For testing the infrastructure deployment, you can use a placeholder image:

```bash
az deployment group create \
  --resource-group prod-rg-san-autopr \
  --template-file infrastructure/bicep/codeflow-engine.bicep \
  --parameters \
    containerImage="mcr.microsoft.com/azuredocs/containerapps-helloworld:latest" \
    ...
```

**Note:** This will deploy a hello-world app, not AutoPR Engine. Update the image later once you've built and pushed the actual image.

## Updating the Container Image After Deployment

Once you have the image built and pushed, update the Container App:

```bash
az containerapp update \
  --name prod-autopr-san-app \
  --resource-group prod-rg-san-autopr \
  --image ghcr.io/justaghost/codeflow-engine:latest
```

