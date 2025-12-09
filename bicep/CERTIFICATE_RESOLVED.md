# âœ… Certificate Issue - RESOLVED

## Your Question:
> "can you sort the certificate or do i need to give you a linkn?"

## Answer
**No certificate link needed! The system automatically sorts (manages) certificates for you!** ðŸŽ‰

Azure Container Apps now automatically provisions and manages free SSL/TLS certificates for your custom domain. You don't need to:

- âŒ Buy a certificate
- âŒ Upload a certificate
- âŒ Provide a certificate link
- âŒ Manually renew certificates

## What Changed?

The `CertificateMissing` error you saw has been **fixed** in the latest code. The Bicep template now includes:

1. **Managed Certificate Resource** - Automatically creates free SSL certificates
2. **Automatic Validation** - Azure validates domain ownership via DNS
3. **Automatic Renewal** - Certificates renew before expiration
4. **Single Deployment** - Everything works in one deployment

## What You Need to Do

### 1. Update Your Code (If Not Already Done)
```bash
git pull origin main
```

### 2. Configure DNS

Add a CNAME record pointing your custom domain to the Container App:
```
Type: CNAME
Name: app.codeflow.io
Value: <Container-App-FQDN>  # Get this from deployment output
```

### 3. Deploy

```bash
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
    postgresLogin="codeflow" \
    postgresPassword="<your-password>" \
    redisPassword="<your-password>"
```

### 4. Wait
- DNS propagation: 15-30 minutes
- Certificate provisioning: 5-15 minutes
- **Total: ~20-45 minutes to working HTTPS**

## Still Getting the Error?

If you still see the `CertificateMissing` error after updating your code:

1. Verify you're using the latest template from `main` branch
2. Check that DNS is configured correctly
3. See detailed troubleshooting in [FAQ.md](./FAQ.md)

## More Information

- **Detailed FAQ**: [FAQ.md](./FAQ.md) - All questions about certificates
- **Deployment Guide**: [README-codeflow-ENGINE.md](./README-codeflow-ENGINE.md) - Complete setup guide
- **Technical Details**: [CERTIFICATE_FIX.md](./CERTIFICATE_FIX.md) - Deep dive into the fix

---

**Summary**: The certificate is automatically sorted (managed) by Azure. No link needed! Just update your code, configure DNS, and deploy. âœ¨
