# Architecture Decision Records (ADR)

Lead-level engineering is graded on decisions and tradeoffs, not tool count.

## Flow

    Developer push
      -> GitHub Actions: build -> Trivy gate -> push to ACR
      -> commit image SHA into gitops/overlays/staging
      -> Argo CD watches Git (auto-sync staging, manual prod)
      -> k3s on Azure VM runs the workload
      -> Prometheus/Grafana + Azure Monitor
      -> Key Vault supplies app-secret via VM managed identity

Layer separation: Terraform PROVISIONS, Ansible CONFIGURES, Argo CD DEPLOYS.

## Decisions

### 1. k3s on a VM, not AKS
- JD asks for VM/VNet/NSG. AKS hides those and adds control-plane cost.
- Tradeoff: no managed control-plane HA. Fine for a demo.
- Production: AKS, or VMSS-backed k3s behind an Azure Load Balancer.

### 2. Terraform provisions, Ansible configures, Argo CD deploys
- Clean tool-per-layer separation, each idempotent and re-runnable.
- Cloud-init rejected: couples provisioning to config, not idempotent.

### 3. Distroless + non-root + multi-stage image
- No shell / no package manager, minimal CVE surface.
- Enforced via the Trivy gate in CI.

### 4. Managed identity + Key Vault, zero secrets in code
- VM identity pulls images (AcrPull) and secrets (Key Vault Secrets User).
- GitHub Actions authenticates to Azure via OIDC.

### 5. Staging auto-syncs, prod is manual
- Fast iteration in staging; human-gated promotion to prod.

### 6. Cost optimization is provisioned, not claimed
- Burstable B2s VM, nightly auto-shutdown, RG budget with 80/100% alerts,
  cost-attribution tags, single node, terraform destroy when idle.

## Scalability vs Elasticity
- Scalability = can it grow. Elasticity = it grows AND shrinks automatically.
- Pod-level (HPA, live) and node-level (VMSS + Cluster Autoscaler, designed).
