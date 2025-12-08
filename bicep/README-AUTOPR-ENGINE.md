# Azure Infrastructure for AutoPR Engine

This directory contains the Azure Bicep infrastructure definitions for deploying the AutoPR Engine application to Azure Container Apps.

## 🔒 SSL/TLS Certificates - No Action Required!

**You do NOT need to provide or upload SSL certificates!** Azure automatically manages free SSL/TLS certificates for your custom domain. Just configure your DNS CNAME record and Azure handles the rest. See [FAQ.md](./FAQ.md) for details.

## Architecture

The deployment includes:
- **Azure Container Apps**: Serverless container hosting for the AutoPR Engine
- **Azure Container Apps Environment**: Managed environment for container apps
- **Azure Database for PostgreSQL (Flexible Server)**: Primary database
- **Azure Cache for Redis**: Caching and session storage
- **Log Analytics Workspace**: Centralized logging and monitoring

**Note:** Uses PostgreSQL Flexible Server. The PostgreSQL server is created in a separate region (configurable via `postgresLocation` parameter) to support regions where Flexible Server is available.

## Naming Convention

All resources follow the pattern: `{env}-autopr-{region}-{resource}`

- **env**: Environment (prod, dev, staging)
- **region**: Azure region abbreviation (san, eus, wus, etc.)
- **resource**: Resource type (app, env, postgres, redis, logs)

### Examples

- `prod-autopr-san-app` - Production Container App
- `prod-autopr-san-env` - Container Apps Environment
- `prod-autopr-san-postgres` - PostgreSQL server
- `prod-autopr-san-redis` - Redis cache
- `prod-autopr-san-logs` - Log Analytics workspace

## Prerequisites

1. Azure CLI installed and configured
2. Appropriate Azure subscription permissions
3. Resource group created: `prod-rg-san-autopr`
4. Docker image built and pushed to container registry

## Deployment

### Option 1: Using the Deployment Script (Recommended)

```bash
bash infrastructure/bicep/deploy-codeflow-engine.sh prod san "eastus2"
```

The script will:
- Create the resource group if it doesn't exist
- **Automatically cleanup duplicate certificates** (prevents deployment errors)
- Generate secure passwords for PostgreSQL and Redis
- Deploy all infrastructure components
- Display the deployment outputs

### Option 2: Manual Deployment

**Important:** If redeploying to an existing environment, first cleanup any duplicate managed certificates to prevent `DuplicateManagedCertificateInEnvironment` errors:

```bash
# Cleanup duplicate certificates (if environment already exists)
bash infrastructure/bicep/cleanup-certificates.sh

# Or use PowerShell on Windows:
# .\infrastructure\bicep\cleanup-certificates.ps1
```

Then proceed with deployment:

1. **Create resource group** (if not exists):
   ```bash
   az group create \
     --name prod-rg-san-autopr \
     --location "eastus2"
   ```

2. **Generate passwords**:
   ```bash
   POSTGRES_LOGIN="autopr"  # Or your custom username
   POSTGRES_PASSWORD=$(openssl rand -base64 32)
   REDIS_PASSWORD=$(openssl rand -base64 32)
   ```

3. **Deploy infrastructure**:
   ```bash
   az deployment group create \
     --resource-group prod-rg-san-autopr \
     --template-file infrastructure/bicep/codeflow-engine.bicep \
     --parameters \
       environment=prod \
       regionAbbr=san \
       location=eastus2 \
       containerImage=ghcr.io/justaghost/codeflow-engine:latest \
       postgresLogin="$POSTGRES_LOGIN" \
       postgresPassword="$POSTGRES_PASSWORD" \
       redisPassword="$REDIS_PASSWORD"
   ```

## Troubleshooting

### DuplicateManagedCertificateInEnvironment Error

If you encounter this error during deployment:

```
ERROR: "DuplicateManagedCertificateInEnvironment"
"message": "Another managed certificate with subject name 'app.*.io' available in environment"
```

**Solution:** Run the certificate cleanup script before deployment:

```bash
# Linux/macOS
bash infrastructure/bicep/cleanup-certificates.sh

# Windows PowerShell
.\infrastructure\bicep\cleanup-certificates.ps1
```

This removes any existing managed certificates for your domain, allowing a clean deployment. The GitHub Actions workflow handles this automatically.

For more details, see [FAQ.md](./FAQ.md).

## Configuration

### Required Parameters

- `environment`: Environment name (prod, dev, staging)
- `regionAbbr`: Region abbreviation (san, eus, wus, etc.)
- `location`: Azure region (eastus2, westus2, etc.)
- `customDomain`: Custom domain for the container app (default: app.autopr.io)
- `containerImage`: Full container image path
- `postgresLogin`: PostgreSQL administrator username (default: autopr)
- `postgresPassword`: PostgreSQL administrator password (secure)
- `redisPassword`: Redis password (secure)

### Environment Variables

The Container App is configured with the following environment variables:

**Application Configuration:**
- `AUTOPR_ENV`: Environment name
- `HOST`: Server host (0.0.0.0)
- `PORT`: Server port (8080)

**PostgreSQL Connection (passwords via secretRef):**
- `POSTGRES_HOST`: PostgreSQL server FQDN
- `POSTGRES_PORT`: PostgreSQL port (5432)
- `POSTGRES_DB`: Database name (autopr)
- `POSTGRES_USER`: Database user (configured via `postgresLogin` parameter, default: autopr)
- `POSTGRES_PASSWORD`: Database password (via secretRef, not plaintext)
- `POSTGRES_SSLMODE`: SSL mode (require)

**Redis Connection (passwords via secretRef):**
- `REDIS_HOST`: Redis cache hostname
- `REDIS_PORT`: Redis port (6380, SSL)
- `REDIS_PASSWORD`: Redis password (via secretRef, not plaintext)
- `REDIS_SSL`: SSL enabled (true)

**Note:** Passwords are stored as Container App secrets and referenced via `secretRef`. The application should construct connection strings at runtime from these individual environment variables rather than using pre-built connection strings with embedded credentials.

### Additional Environment Variables

You can add additional environment variables (like GitHub tokens, AI API keys) through:
1. Azure Portal → Container App → Configuration → Environment variables
2. Azure CLI: `az containerapp update`
3. Update the Bicep template to include them as secrets

## Post-Deployment

### Get Deployment Outputs

```bash
az deployment group show \
  --resource-group prod-rg-san-autopr \
  --name codeflow-engine \
  --query properties.outputs \
  --output json
```

### Update Container Image

To update the container image after deployment:

```bash
az containerapp update \
  --name prod-autopr-san-app \
  --resource-group prod-rg-san-autopr \
  --image ghcr.io/justaghost/codeflow-engine:latest
```

### View Logs

```bash
az containerapp logs show \
  --name prod-autopr-san-app \
  --resource-group prod-rg-san-autopr \
  --follow
```

### Scale the Application

```bash
# Scale to 3 replicas
az containerapp update \
  --name prod-autopr-san-app \
  --resource-group prod-rg-san-autopr \
  --min-replicas 1 \
  --max-replicas 10
```

## Database Access

### Connect to PostgreSQL

```bash
# Get connection details
az postgres flexible-server show \
  --name prod-autopr-san-postgres-<unique-suffix> \
  --resource-group prod-rg-san-autopr \
  --query "{fqdn:fullyQualifiedDomainName,adminUser:administratorLogin}" \
  --output json

# Connect using psql
psql -h <fqdn> -U <postgres_login> -d autopr
```

**Note:** The PostgreSQL username is configured via the `postgresLogin` parameter (defaults to 'autopr'). For production deployments using GitHub Actions, set the `AUTOPR_POSTGRES_LOGIN` secret to customize the username.

### Connect to Redis

```bash
# Get Redis connection details
az redis show \
  --name prod-autopr-san-redis \
  --resource-group prod-rg-san-autopr \
  --query "{hostName:hostName,sslPort:sslPort}" \
  --output json
```

## Monitoring

### View Application Metrics

1. Azure Portal → Container App → Metrics
2. Monitor CPU, memory, request count, response time

### View Logs

1. Azure Portal → Container App → Log stream
2. Or use Log Analytics workspace: `prod-autopr-san-logs`

## Cost Estimation

- **Container Apps**: ~$0.000012/vCPU-second + $0.0000015/GB-second
- **Container Apps Environment**: Included (no additional cost)
- **PostgreSQL Flexible Server (Standard_B1ms)**: ~$12/month
- **Redis (Basic C1)**: ~$15/month
- **Log Analytics**: ~$2.30/GB ingested

Total estimated monthly cost: ~$30-50 for light usage, $100-200 for moderate usage.

## Troubleshooting

### Certificate Deployment Error: "CertificateMissing"

If you see an error like:
```
ERROR: "code": "CertificateMissing", 
"message": "CertificateId property is missing for customDomain"
```

**Solution**: This has been fixed! Make sure you're using the latest version from the `main` branch. See the detailed [FAQ.md](./FAQ.md) for step-by-step resolution.

### Container App Not Starting

1. Check logs: `az containerapp logs show --name prod-autopr-san-app --resource-group prod-rg-san-autopr`
2. Verify container image exists and is accessible
3. Check environment variables are set correctly
4. Verify database and Redis connectivity

### Database Connection Issues

1. Check firewall rules allow Azure services
2. Verify PostgreSQL server is running
3. Check connection string format
4. Verify credentials

### Redis Connection Issues

1. Verify Redis cache is running
2. Check SSL/TLS settings match connection string
3. Verify password is correct
4. Check firewall rules if applicable

### DNS and Certificate Issues

See [FAQ.md](./FAQ.md) for common questions about:

- Certificate management (automated, no action needed!)
- DNS configuration requirements
- Certificate validation timeline
- Troubleshooting custom domain setup

## Security Best Practices

1. **Use Azure Key Vault** for storing passwords instead of passing them directly
2. **Enable Private Endpoints** for database and Redis in production
3. **Use Managed Identity** for authentication where possible
4. **Enable SSL/TLS** for all connections
5. **Regularly rotate** passwords and secrets
6. **Enable Azure Defender** for threat detection
7. **Use Network Security Groups** to restrict access

## Custom Domain and SSL Certificate

The infrastructure template now includes automatic setup of managed SSL certificates for custom domains:

- **Managed Certificate**: A free Azure-managed SSL certificate is automatically created for the custom domain
- **API Version**: Uses `2024-10-02-preview` which supports managed certificates in a single deployment
- **Certificate Validation**: Azure validates domain ownership via CNAME records
- **Automatic Renewal**: SSL certificates are automatically renewed by Azure

**Important**: Before deploying, ensure your DNS is configured with the required CNAME record pointing to the Container App FQDN. Azure will validate domain ownership during certificate provisioning.

## Next Steps

1. **Configure custom domain DNS records** (REQUIRED before deployment):
   - Add a CNAME record for your custom domain (e.g., app.autopr.io) pointing to the Container App FQDN
   - You may need to deploy once without the custom domain first, then update DNS, then redeploy
   - Obtain the FQDN from deployment outputs: `az deployment group show --resource-group prod-rg-san-autopr --name codeflow-engine --query properties.outputs.containerAppUrl.value`
   - Example DNS record: `CNAME app.autopr.io -> prod-autopr-san-app.<region>.azurecontainerapps.io`
   - The managed SSL certificate will be automatically provisioned by Azure after DNS validation
2. Set up GitHub Actions for CI/CD (see `.github/workflows/deploy-codeflow-engine.yml`)
3. Configure additional environment variables (GitHub tokens, AI API keys)
4. Set up monitoring alerts
5. Configure backup and disaster recovery

