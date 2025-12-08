# CodeFlow Infrastructure

Production infrastructure as code (IaC) for CodeFlow - the source of truth for live environments.

## Purpose

This repository contains CodeFlow-specific infrastructure definitions using Bicep and Terraform. This is where "real" infrastructure lives and is deployed from.

**Important**: This repository contains production-grade, CodeFlow-specific infrastructure. For generic bootstrap scripts that can be used for any repository, see [`codeflow-azure-setup`](https://github.com/JustAGhosT/codeflow-azure-setup).

## Infrastructure Components

### 1. AutoPR Engine Application (`bicep/codeflow-engine.bicep`)

Production-ready infrastructure for the AutoPR Engine application:
- **Azure Container Apps**: Serverless container hosting
- **Azure Database for PostgreSQL**: Primary database
- **Azure Cache for Redis**: Caching and session storage
- **Log Analytics Workspace**: Centralized logging

See [README-AUTOPR-ENGINE.md](bicep/README-AUTOPR-ENGINE.md) for deployment instructions.

### 2. Website (`bicep/website.bicep`)

Marketing website infrastructure:
- **Azure Static Web Apps**: Hosting for Next.js website

See [README-WEBSITE.md](bicep/README-WEBSITE.md) for deployment instructions.

### 3. Legacy Infrastructure (`bicep/main.bicep`)

Original infrastructure template (AKS, ACR, PostgreSQL, Redis):
- **Azure Kubernetes Service (AKS)**: Container orchestration
- **Azure Container Registry (ACR)**: Container image storage
- **PostgreSQL**: Database server
- **Redis**: Cache server

## Deployment Options

### Bicep (Recommended for Azure)

Bicep is the native Azure IaC language and is recommended for Azure deployments:

**AutoPR Engine:**
```bash
bash bicep/deploy-codeflow-engine.sh prod san "eastus2"
```

**Website:**
```bash
az group create --name prod-rg-san-autopr --location "eastus2"
az deployment group create \
  --resource-group prod-rg-san-autopr \
  --template-file bicep/website.bicep \
  --parameters @bicep/website-parameters.json
```

### Terraform

Terraform is located in the `terraform` directory and provides a cloud-agnostic option:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Naming Convention

All resources follow the pattern: `{env}-{resourcetype}-{region}-autopr`

- **env**: Environment (prod, dev, staging)
- **resourcetype**: Resource type abbreviation (stapp, autopr, rg, etc.)
- **region**: Azure region abbreviation (san, eus, wus, etc.)

Examples:
- `prod-stapp-san-autopr` - Static Web App
- `prod-autopr-san-app` - Container App
- `prod-rg-san-autopr` - Resource Group

## Repository Structure

```
codeflow-infrastructure/
├── bicep/              # Bicep templates
│   ├── codeflow-engine.bicep
│   ├── website.bicep
│   └── ...
├── terraform/          # Terraform configurations
│   ├── main.tf
│   └── ...
├── .github/
│   └── workflows/     # Deployment workflows
└── README.md
```

## Boundary Rules

**This repository contains**:
- ✅ CodeFlow-specific infrastructure
- ✅ Production environments (prod/dev/uat)
- ✅ Real infrastructure that is source of truth
- ✅ Deployment workflows

**This repository does NOT contain**:
- ❌ Generic bootstrap scripts (see `codeflow-azure-setup`)
- ❌ Application code (see `codeflow-engine`)
- ❌ Reusable, org-agnostic scripts

## CI/CD

Deployment workflows are located in `.github/workflows/` and can:
- Trigger deployments for specific environments
- Coordinate deployments across multiple repositories
- Manage infrastructure lifecycle

## License

MIT
