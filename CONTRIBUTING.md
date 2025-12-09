# Contributing to CodeFlow Infrastructure

Thank you for your interest in contributing to CodeFlow Infrastructure! This document provides guidelines for infrastructure as code contributions.

---

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Set up development environment**:
   - Azure CLI installed and configured
   - Bicep CLI installed (optional)
   - Terraform installed (if contributing Terraform)
4. **Create a branch** for your changes

---

## Development Workflow

### Prerequisites

- Azure CLI
- Bicep CLI (optional, for Bicep templates)
- Terraform (for Terraform contributions)
- PowerShell or Bash

### Validating Changes

**Bicep Templates:**
```bash
# Validate Bicep file
az bicep build --file bicep/main.bicep

# Validate all templates
find bicep -name "*.bicep" -exec az bicep build --file {} \;
```

**Terraform:**
```bash
# Format
terraform fmt -recursive

# Validate
terraform init
terraform validate
```

### Code Style

- Follow Bicep best practices
- Use consistent naming conventions
- Add comments for complex logic
- Validate all templates before committing

---

## Pull Request Process

1. **Validate all templates** before submitting
2. **Update documentation** as needed
3. **Test in a development environment** (if possible)
4. **Create a pull request** with a clear description

### PR Checklist

- [ ] All Bicep/Terraform templates validated
- [ ] Documentation updated
- [ ] No hardcoded secrets or credentials
- [ ] Resource naming follows conventions
- [ ] Tested in development environment (if applicable)

---

## Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(infra): add Redis cache to Bicep template

Add Azure Cache for Redis to main.bicep.
Configure SSL and password authentication.

Closes #123
```

---

## Reporting Issues

Use GitHub Issues with:
- Clear description
- Affected template/file
- Expected vs actual behavior
- Azure subscription details (if applicable)
- Error messages or logs

---

## Questions?

- GitHub Discussions: For questions
- GitHub Issues: For bugs and features
- See [main CONTRIBUTING guide](../../codeflow-orchestration/docs/CONTRIBUTING_TEMPLATE.md) for more details

---

Thank you for contributing! 🎉

