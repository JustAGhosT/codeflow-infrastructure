# ⚠️ DEPRECATED - Repository Archived

> **This repository has been merged into [codeflow-orchestration](https://github.com/JustAGhosT/codeflow-orchestration).**

---

## New Location

All infrastructure code has been moved to the `codeflow-orchestration` repository:

| Component | Old Location | New Location |
|-----------|--------------|--------------|
| Bicep templates | `bicep/` | `codeflow-orchestration/infrastructure/bicep/` |
| Terraform | `terraform/` | `codeflow-orchestration/infrastructure/terraform/` |
| Kubernetes | `kubernetes/` | `codeflow-orchestration/infrastructure/kubernetes/` |
| Docker | `docker/` | `codeflow-orchestration/infrastructure/docker/` |
| CI/CD Workflows | `.github/workflows/` | `codeflow-orchestration/infrastructure/.github/workflows/` |

---

## Migration Guide

### Clone the New Repository

```bash
git clone https://github.com/JustAGhosT/codeflow-orchestration.git
cd codeflow-orchestration/infrastructure
```

### Update Your Workflows

If you have workflows referencing this repository, update them to use:

```yaml
# Old
- uses: actions/checkout@v4
  with:
    repository: JustAGhosT/codeflow-infrastructure

# New
- uses: actions/checkout@v4
  with:
    repository: JustAGhosT/codeflow-orchestration
    path: orchestration

# Then reference: orchestration/infrastructure/bicep/...
```

### Update Your Bookmarks

- **Old:** `https://github.com/JustAGhosT/codeflow-infrastructure`
- **New:** `https://github.com/JustAGhosT/codeflow-orchestration/tree/main/infrastructure`

---

## Why This Change?

1. **Single source of truth** - All infrastructure and orchestration in one place
2. **Simplified CI/CD** - One repository to manage all deployment automation
3. **Better discoverability** - Contributors find everything in one place
4. **Reduced repository sprawl** - 7 repos → 5 repos

---

## Questions?

If you have questions about this migration, please:
1. Open an issue in [codeflow-orchestration](https://github.com/JustAGhosT/codeflow-orchestration/issues)
2. Review the [Infrastructure Consolidation Plan](https://github.com/JustAGhosT/codeflow-orchestration/blob/main/docs/INFRASTRUCTURE_CONSOLIDATION_PLAN.md)

---

**Archived:** 2025-01-XX
**Migration completed by:** Infrastructure Team
