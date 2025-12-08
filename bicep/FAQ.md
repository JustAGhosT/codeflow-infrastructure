# Azure Container Apps Deployment FAQ

## Certificate Management

### Q: Do I need to provide a certificate or certificate link for the custom domain?

**A: No, you do not need to provide a certificate!** 

Azure Container Apps automatically manages SSL/TLS certificates for your custom domain at no additional cost. The deployment template is configured to use **Azure Managed Certificates**, which means:

✅ **Automatic Certificate Provisioning**: Azure creates a free SSL certificate for your domain
✅ **Automatic Renewal**: Certificates are renewed before expiration without any manual intervention
✅ **No Certificate Upload Required**: You don't need to buy, upload, or manage certificates
✅ **Single Deployment**: Everything is configured in one deployment step

### What You DO Need to Provide:

1. **A custom domain name** (e.g., `app.autopr.io`)
2. **DNS CNAME record** pointing your domain to the Container App FQDN

### DNS Configuration Steps

Before or immediately after deployment, add a CNAME record:

```
Type: CNAME
Name: app.autopr.io (or your subdomain)
Value: prod-autopr-san-app.eastus2.azurecontainerapps.io
TTL: 3600 (or default)
```

To get your Container App FQDN after deployment:
```bash
az deployment group show \
  --resource-group prod-rg-san-autopr \
  --name codeflow-engine \
  --query properties.outputs.containerAppUrl.value
```

### Certificate Provisioning Timeline:

After DNS is configured:
- ⏱️ **DNS Propagation**: 15-30 minutes (varies by DNS provider)
- ⏱️ **Certificate Validation**: 5-15 minutes (Azure validates domain ownership)
- ⏱️ **Certificate Provisioning**: Automatic (Azure creates and binds the certificate)

Total time: Typically 20-45 minutes from DNS configuration to working HTTPS.

---

## Common Error: "RequireCustomHostnameInEnvironment"

### Error Message:
```
ERROR: "status":"Failed","error":{"code":"DeploymentFailed"
"code":"RequireCustomHostnameInEnvironment"
"message":"Creating managed certificate requires hostname 'app.*.io' added as a custom hostname to a container app or route in environment 'prod-*-san-env'"
```

### What This Means

This is a **deployment ordering issue**. Azure requires the custom hostname to be added to a container app **before** a managed certificate can be created for it. This is a "chicken-and-egg" problem that occurs when:

1. **The Bicep template tries to create the managed certificate first** before the container app exists
2. **Azure validates the certificate creation** and finds no container app with that hostname
3. **The deployment fails** because the prerequisite is not met

### Root Cause

In earlier versions of the template, the resources were defined in this order:
1. Container App Environment
2. **Managed Certificate** (requires hostname to exist)
3. Container App (adds the hostname)

This caused the deployment to fail because step 2 tried to validate before step 3 completed.

### The Fix (Implemented)

The template has been updated to fix this issue by:

1. **Reordering resources**: The managed certificate is now created **after** the container app
2. **Using `bindingType: 'Auto'`**: This allows Azure to automatically bind the certificate once it's provisioned
3. **Adding explicit dependency**: The certificate resource includes `dependsOn: [containerApp]`

The deployment now follows this correct order:
1. Container App Environment
2. Container App (adds the hostname with `bindingType: 'Auto'`)
3. Managed Certificate (can now validate because hostname exists)
4. Azure automatically binds the certificate to the hostname

### What You Need to Do

**Nothing!** If you're using the latest version of the template (after this fix), the deployment will work correctly. The changes are:

✅ **Container app created first** with custom domain configured
✅ **Certificate created second** after hostname is added
✅ **Automatic certificate binding** via `bindingType: 'Auto'`
✅ **Single deployment** - no need for two-step process

### Verification

After deployment, you can verify the setup:

```bash
# Check that the container app has the custom domain
az containerapp show \
  --name prod-autopr-san-app \
  --resource-group prod-rg-san-autopr \
  --query "properties.configuration.ingress.customDomains"

# Check that the managed certificate was created
az containerapp env certificate list \
  --name prod-autopr-san-env \
  --resource-group prod-rg-san-autopr \
  --query "[?properties.subjectName=='app.autopr.io']"
```

### If You're Using an Older Template Version

If you have an older version of the template that doesn't include this fix:

1. **Pull the latest changes** from the repository
2. **Redeploy** using the updated template

The updated template is backward compatible and will work with existing deployments.

---

## Common Error: "DuplicateManagedCertificateInEnvironment"

### Error Message:
```
ERROR: "code": "DeploymentFailed"
"code": "DuplicateManagedCertificateInEnvironment"
"message": "Another managed certificate with subject name 'app.*.io' and certificate name 'app.*.io-prod-aut-251205170140' available in environment 'prod-*-san-env'."
```

### What This Means

Azure Container Apps allows only **ONE managed certificate per domain per environment**. This error occurs when:

1. **Previous deployment created a certificate** that still exists in the environment
2. **New deployment tries to create another certificate** for the same domain
3. **Azure rejects the duplicate** to prevent conflicts

### Automatic Fix (GitHub Actions)

If you're using the GitHub Actions workflow (`.github/workflows/deploy-codeflow-engine.yml`), this is **automatically handled** for you! The workflow includes a cleanup step that:

1. ✅ Checks for existing managed certificates for your domain
2. ✅ Removes any duplicates before deployment
3. ✅ Ensures clean deployment every time

### Manual Fix

If deploying manually with Azure CLI, run this cleanup script before deployment:

```bash
# Set your environment variables
RESOURCE_GROUP="prod-rg-san-autopr"
ENV_NAME="prod-autopr-san-env"
CUSTOM_DOMAIN="app.autopr.io"

# List all managed certificates for the domain
az containerapp env certificate list \
  --name $ENV_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "[?properties.subjectName=='$CUSTOM_DOMAIN' && type=='Microsoft.App/managedEnvironments/managedCertificates'].name" \
  --output tsv | while read -r cert_name; do
  echo "Deleting duplicate certificate: $cert_name"
  az containerapp env certificate delete \
    --name $ENV_NAME \
    --resource-group $RESOURCE_GROUP \
    --certificate "$cert_name" \
    --yes
done

# Now deploy your template
az deployment group create \
  --name codeflow-engine \
  --resource-group $RESOURCE_GROUP \
  --template-file infrastructure/bicep/codeflow-engine.bicep \
  --parameters customDomain=$CUSTOM_DOMAIN ...
```

### Why This Happens

- Each deployment may try to create a certificate with the same domain name
- Azure maintains strict uniqueness constraint on managed certificates per domain
- Old certificates may not be automatically cleaned up when redeploying
- The cleanup ensures idempotent deployments

### Prevention

- Use the GitHub Actions workflow which handles cleanup automatically
- If deploying manually, always run the cleanup script first
- The deployment is now designed to be fully idempotent

---

## Common Error: "CertificateMissing"

### Error Message:
```
ERROR: "code": "InvalidTemplateDeployment"
Inner Errors: "code": "CertificateMissing", 
"message": "CertificateId property is missing for customDomain 'app.*.io'."
```

### This error occurs if:

1. **Using an older version of the template** that doesn't have managed certificate support
   - **Solution**: Pull the latest version from the `main` branch
   - The fix was implemented in commit `7337442`

2. **DNS is not configured** before deployment
   - **Solution**: Configure DNS first, or deploy without custom domain initially, then add it later
   - See "DNS Configuration Steps" above

### How to Fix:

#### Option 1: Update to Latest Template (Recommended)
```bash
# Pull latest changes
git pull origin main

# Redeploy with the updated template
az deployment group create \
  --name codeflow-engine \
  --resource-group prod-rg-san-autopr \
  --template-file infrastructure/bicep/codeflow-engine.bicep \
  --parameters \
    environment=prod \
    regionAbbr=san \
    location=eastus2 \
    customDomain=app.autopr.io \
    containerImage=ghcr.io/justaghost/codeflow-engine:latest \
    postgresLogin="<your-login>" \
    postgresPassword="<your-password>" \
    redisPassword="<your-password>"
```

#### Option 2: Deploy Without Custom Domain First

```bash
# Deploy without customDomain parameter
az deployment group create \
  --name codeflow-engine \
  --resource-group prod-rg-san-autopr \
  --template-file infrastructure/bicep/codeflow-engine.bicep \
  --parameters \
    environment=prod \
    regionAbbr=san \
    location=eastus2 \
    containerImage=ghcr.io/justaghost/codeflow-engine:latest \
    postgresLogin="<your-login>" \
    postgresPassword="<your-password>" \
    redisPassword="<your-password>"

# Configure DNS with the Container App FQDN

# Redeploy with custom domain
az deployment group create \
  --name codeflow-engine \
  --resource-group prod-rg-san-autopr \
  --template-file infrastructure/bicep/codeflow-engine.bicep \
  --parameters \
    environment=prod \
    regionAbbr=san \
    location=eastus2 \
    customDomain=app.autopr.io \
    containerImage=ghcr.io/justaghost/codeflow-engine:latest \
    postgresLogin="<your-login>" \
    postgresPassword="<your-password>" \
    redisPassword="<your-password>"
```

---

## Verification

### Check Certificate Status:
```bash
az containerapp show \
  --name prod-autopr-san-app \
  --resource-group prod-rg-san-autopr \
  --query "properties.configuration.ingress.customDomains"
```

### Check Managed Certificate
```bash
az containerapp env certificate list \
  --name prod-autopr-san-env \
  --resource-group prod-rg-san-autopr
```

### Test HTTPS:

```bash
curl -I https://app.autopr.io
```

---

## Additional Resources

- **Detailed Technical Explanation**: See [CERTIFICATE_FIX.md](./CERTIFICATE_FIX.md)
- **Deployment Guide**: See [README-AUTOPR-ENGINE.md](./README-AUTOPR-ENGINE.md)
- **Azure Documentation**: [Container Apps Custom Domains](https://learn.microsoft.com/en-us/azure/container-apps/custom-domains-certificates)
