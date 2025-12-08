# Next Steps After Successful Deployment

## ✅ Deployment Complete

Your Static Web App has been successfully deployed:
- **Name**: `prod-stapp-san-autopr`
- **URL**: `witty-bush-07121230f.3.azurestaticapps.net`
- **Resource Group**: `prod-rg-san-autopr`
- **Location**: `eastus2`

## 1. Get Deployment Token for GitHub Actions

You need to retrieve the deployment token and add it as a GitHub secret:

```bash
az staticwebapp secrets list \
  --name prod-stapp-san-autopr \
  --resource-group prod-rg-san-autopr \
  --query "properties.apiKey" \
  --output tsv
```

Copy the output and add it as `AZURE_STATIC_WEB_APPS_API_TOKEN` in your GitHub repository secrets:
1. Go to your GitHub repository
2. Settings → Secrets and variables → Actions
3. New repository secret
4. Name: `AZURE_STATIC_WEB_APPS_API_TOKEN`
5. Value: (paste the token from above)

## 2. Configure Custom Domain (autopr.io)

### Step 1: Get Domain Validation Token

```bash
az staticwebapp hostname show \
  --name prod-stapp-san-autopr \
  --resource-group prod-rg-san-autopr \
  --hostname autopr.io
```

This will return a validation token that you need to add as a DNS TXT record.

### Step 2: Add DNS TXT Record

Add a TXT record to your domain provider:
- **Record Type**: TXT
- **Name**: `asuid.autopr.io` (or as specified by Azure)
- **Value**: (the validation token from Step 1)
- **TTL**: 3600 (or default)

### Step 3: Wait for Validation

Azure will automatically validate the domain (usually takes 5-10 minutes). You can check the status:

```bash
az staticwebapp hostname list \
  --name prod-stapp-san-autopr \
  --resource-group prod-rg-san-autopr
```

### Step 4: Add CNAME Record (if needed)

After validation, you may need to add a CNAME record:
- **Record Type**: CNAME
- **Name**: `autopr.io` (or `www.autopr.io`)
- **Value**: `witty-bush-07121230f.3.azurestaticapps.net`

## 3. Test the Deployment

Visit your Static Web App:
- **Default URL**: https://witty-bush-07121230f.3.azurestaticapps.net
- **Custom Domain** (after DNS setup): https://autopr.io

## 4. Verify GitHub Actions Integration

Once you've added the `AZURE_STATIC_WEB_APPS_API_TOKEN` secret, push a change to the `website/` directory to trigger automatic deployment:

```bash
git add .
git commit -m "Test website deployment"
git push origin main
```

The GitHub Actions workflow will automatically build and deploy your Next.js site.

## 5. Monitor Deployment

Check deployment status in:
- **Azure Portal**: Resource Group → Static Web App → Deployment history
- **GitHub Actions**: Repository → Actions tab

## Troubleshooting

### If deployment fails:
1. Check GitHub Actions logs
2. Verify `AZURE_STATIC_WEB_APPS_API_TOKEN` is correct
3. Ensure the `website/` directory exists and has valid Next.js code
4. Check build logs in Azure Portal

### If custom domain doesn't work:
1. Verify DNS records are correct (use `nslookup` or `dig`)
2. Wait 10-15 minutes for DNS propagation
3. Check domain validation status in Azure Portal
4. Ensure SSL certificate is provisioned (automatic for Static Web Apps)

