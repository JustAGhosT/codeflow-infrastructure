# Certificate Validation Error Fix

## Problem

The Azure deployment was failing with the following error:

```
ERROR: "code": "InvalidTemplateDeployment", "message": "The template deployment 'codeflow-engine' is not valid according to the validation procedure."

Inner Errors: 
"code": "CertificateMissing", "message": "CertificateId property is missing for customDomain 'app.codeflow.io'."
```

## Root Cause

The Bicep template was attempting to configure a custom domain on Azure Container Apps without providing a certificate. Starting with recent API versions, Azure Container Apps requires an explicit certificate reference when configuring custom domains.

## Solution

The fix involves three key changes to the `codeflow-engine.bicep` file:

### 1. Updated API Versions

Changed from `2023-05-01` to `2024-10-02-preview` for:

- `Microsoft.App/managedEnvironments`
- `Microsoft.App/containerApps`

This newer API version supports managed certificates and simplified custom domain configuration.

### 2. Added Managed Certificate Resource

```bicep
resource managedCertificate 'Microsoft.App/managedEnvironments/managedCertificates@2024-10-02-preview' = {
  parent: containerAppEnv
  name: 'cert-${replace(customDomain, '.', '-')}'
  location: location
  properties: {
    subjectName: customDomain
    domainControlValidation: 'CNAME'
  }
}
```

This creates a free Azure-managed SSL certificate for the custom domain. Azure will automatically:



- Validate domain ownership via CNAME records
- Provision the certificate
- Renew the certificate before expiration

### 3. Linked Certificate to Custom Domain

```bicep
customDomains: [
  {
    name: customDomain
    certificateId: managedCertificate.id  // Added this line
    bindingType: 'SniEnabled'
  }
]
```

The `certificateId` property now references the managed certificate resource.

## Deployment Requirements

Before deploying with a custom domain:

1. **DNS Configuration**: Ensure your DNS has a CNAME record pointing to the Container App FQDN
   - Example: `CNAME app.codeflow.io -> prod-codeflow-san-app.eastus2.azurecontainerapps.io`
2. **Initial Deployment**: If DNS is not yet configured, you have two options:
   - Deploy without the custom domain first, configure DNS, then redeploy
   - Configure DNS before the first deployment (recommended)

3. **Certificate Provisioning**: After deployment, Azure will:
   - Validate domain ownership via the CNAME record
   - Provision a free managed certificate
   - Bind the certificate to the custom domain
   - This process typically takes 5-15 minutes

## Benefits

- **Free SSL/TLS certificates**: Azure manages certificate provisioning and renewal at no cost
- **Automatic renewal**: No manual intervention needed for certificate updates
- **Single deployment**: With proper DNS configuration, everything deploys in one step
- **Simplified management**: No need to upload or manage certificates manually

## Testing

To verify the fix works:

```bash
# Deploy the infrastructure
az deployment group create \
  --name codeflow-engine \
  --resource-group prod-rg-san-codeflow \
  --template-file infrastructure/bicep/codeflow-engine.bicep \
  --parameters \
    environment=prod \
    regionAbbr=san \
    location=eastus2 \
    customDomain=app.codeflow.io \
    containerImage=ghcr.io/justaghost/codeflow-engine:latest \
    postgresLogin="<login>" \
    postgresPassword="<password>" \
    redisPassword="<password>"

# Check certificate status
az containerapp show \
  --name prod-codeflow-san-app \
  --resource-group prod-rg-san-codeflow \
  --query "properties.configuration.ingress.customDomains"
```

## References

- [Azure Container Apps Custom Domains Documentation](https://learn.microsoft.com/en-us/azure/container-apps/custom-domains-certificates)
- [Managed Certificates Overview](https://learn.microsoft.com/en-us/azure/container-apps/certificates-overview)
- [Azure Container Apps API Reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.app/2024-10-02-preview/containerapps)
