# Azure Infrastructure Deployment

This directory contains Azure Bicep templates and documentation for deploying AutoPR infrastructure.

## 🎉 Certificate Issue RESOLVED!

**Having certificate errors?** The `CertificateMissing` error has been fixed! Azure now automatically manages SSL certificates. See **[CERTIFICATE_RESOLVED.md](./CERTIFICATE_RESOLVED.md)** for the quick answer.

## 📚 Documentation

### Quick Start
- **[FAQ.md](./FAQ.md)** - ⭐ **START HERE!** Common questions and troubleshooting (especially for certificate errors)
- **[README-AUTOPR-ENGINE.md](./README-AUTOPR-ENGINE.md)** - Complete deployment guide for AutoPR Engine
- **[README-WEBSITE.md](./README-WEBSITE.md)** - Website deployment guide

### Technical Details

- **[CERTIFICATE_FIX.md](./CERTIFICATE_FIX.md)** - Deep dive into managed certificate implementation
- **[BUILD_AND_PUSH_IMAGE.md](./BUILD_AND_PUSH_IMAGE.md)** - Container image build process
- **[NEXT_STEPS.md](./NEXT_STEPS.md)** - Post-deployment configuration

## ⚡ Quick Answers

### "Do I need to provide a certificate?"
**No!** Azure automatically manages SSL certificates for you. See [FAQ.md](./FAQ.md).

### "I'm getting a 'CertificateMissing' error"

This has been fixed. Pull the latest code from `main` branch. See [FAQ.md](./FAQ.md) for details.

### "How do I deploy?"
Follow the deployment guide in [README-AUTOPR-ENGINE.md](./README-AUTOPR-ENGINE.md).

## 📂 Files

### Bicep Templates
- `codeflow-engine.bicep` - Main infrastructure template for AutoPR Engine
- `website.bicep` - Static web app template
- `main.bicep` - Combined deployment template

### Parameter Files
- `codeflow-engine-parameters.json` - Example parameters for AutoPR Engine
- `website-parameters.json` - Example parameters for website

### Deployment Scripts

- `deploy-codeflow-engine.sh` - Bash deployment script
- `deploy-codeflow-engine.ps1` - PowerShell deployment script
- `deploy-website.sh` - Website deployment script
- `cleanup-codeflow-engine.sh` - Resource cleanup script

## 🚀 Quick Deploy

### Prerequisites


1. Azure CLI installed
2. Appropriate Azure subscription permissions
3. Docker image built and pushed (for AutoPR Engine)

### Deploy AutoPR Engine

**Option 1: Using the script**
```bash
bash deploy-codeflow-engine.sh prod san "eastus2"
```

**Option 2: Manual deployment**
```bash
az deployment group create \
  --name codeflow-engine \
  --resource-group prod-rg-san-autopr \
  --template-file codeflow-engine.bicep \
  --parameters \
    environment=prod \
    regionAbbr=san \
    location=eastus2 \
    customDomain=app.autopr.io \
    containerImage=ghcr.io/justaghost/codeflow-engine:latest \
    postgresLogin="autopr" \
    postgresPassword="$(openssl rand -base64 32)" \
    redisPassword="$(openssl rand -base64 32)"
```

### Deploy Website

```bash
bash deploy-website.sh prod san "eastus2"
```

## 🆘 Need Help?

1. **Check [FAQ.md](./FAQ.md)** for common issues
2. **Review error messages** and search in FAQ
3. **Check Azure Portal** for deployment status and logs
4. **Review [troubleshooting section](./README-AUTOPR-ENGINE.md#troubleshooting)** in the main README

## 🔒 Security Notes

- Passwords are automatically generated and stored as Container App secrets
- For production: Store credentials in GitHub Secrets (`AUTOPR_POSTGRES_PASSWORD`, `AUTOPR_REDIS_PASSWORD`)
- SSL/TLS is enforced for all connections
- Managed certificates are used for HTTPS (no manual certificate management needed)

## 📝 Architecture

The deployment creates:

- **Azure Container Apps**: Hosts the AutoPR Engine application
- **Azure Database for PostgreSQL**: Primary database
- **Azure Cache for Redis**: Caching and session storage
- **Log Analytics Workspace**: Monitoring and logging
- **Managed SSL Certificate**: Automatic HTTPS for custom domains

For detailed architecture information, see [README-AUTOPR-ENGINE.md](./README-AUTOPR-ENGINE.md#architecture).
