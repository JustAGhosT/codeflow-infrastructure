# CodeFlow Infrastructure

Production infrastructure as code (IaC) for CodeFlow - the source of truth for live environments.

## Purpose

This repository contains CodeFlow-specific infrastructure definitions using Bicep and Terraform. This is where "real" infrastructure lives and is deployed from.

**Important**: This repository contains production-grade, CodeFlow-specific infrastructure. For generic bootstrap scripts that can be used for any repository, see [`codeflow-azure-setup`](https://github.com/JustAGhosT/codeflow-azure-setup).

## Infrastructure Components

### 1. CodeFlow Engine Application (`bicep/codeflow-engine.bicep`)

Production-ready infrastructure for the CodeFlow Engine application:
- **Azure Container Apps**: Serverless container hosting
- **Azure Database for PostgreSQL**: Primary database
- **Azure Cache for Redis**: Caching and session storage
- **Log Analytics Workspace**: Centralized logging

See [README-CODEFLOW-ENGINE.md](bicep/README-CODEFLOW-ENGINE.md) for deployment instructions.

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

**CodeFlow Engine:**
```bash
bash bicep/deploy-codeflow-engine.sh prod san "eastus2"
```

**Website:**
```bash
az group create --name prod-rg-san-codeflow --location "eastus2"
az deployment group create \
  --resource-group prod-rg-san-codeflow \
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

All resources follow the pattern: `{env}-{resourcetype}-{region}-codeflow`

- **env**: Environment (prod, dev, staging)
- **resourcetype**: Resource type abbreviation (stapp, codeflow, rg, etc.)
- **region**: Azure region abbreviation (san, eus, wus, etc.)

Examples:
- `prod-stapp-san-codeflow` - Static Web App
- `prod-codeflow-san-app` - Container App
- `prod-rg-san-codeflow` - Resource Group

## Repository Structure

```
codeflow-infrastructure/
â”œâ”€â”€ bicep/              # Bicep templates
â”‚   â”œâ”€â”€ codeflow-engine.bicep
â”‚   â”œâ”€â”€ website.bicep
â”‚   â””â”€â”€ ...
â”œâ”€â”€ terraform/          # Terraform configurations
â”‚   â”œâ”€â”€ main.tf
â”‚   â””â”€â”€ ...
â”œâ”€â”€ .github/
â”‚   â””â”€â”€ workflows/     # Deployment workflows
â””â”€â”€ README.md
```

## Boundary Rules

**This repository contains**:
- âœ… CodeFlow-specific infrastructure
- âœ… Production environments (prod/dev/uat)
- âœ… Real infrastructure that is source of truth
- âœ… Deployment workflows

**This repository does NOT contain**:
- âŒ Generic bootstrap scripts (see `codeflow-azure-setup`)
- âŒ Application code (see `codeflow-engine`)
- âŒ Reusable, org-agnostic scripts

## CI/CD

Deployment workflows are located in `.github/workflows/` and can:
- Trigger deployments for specific environments
- Coordinate deployments across multiple repositories
- Manage infrastructure lifecycle

## License

MIT
