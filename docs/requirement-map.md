# JD Requirement -> Deliverable Map

| JD requirement | Deliverable | Status |
|---|---|---|
| Azure VM | infra/terraform/main.tf | Live |
| VNet | main.tf virtual_network + subnet | Live |
| NSG | main.tf least-privilege rules | Live |
| Azure Monitor | monitoring.tf LAW + agent + CPU alert | Live |
| IAM | VM system-assigned managed identity + RBAC | Live |
| Secrets management | Azure Key Vault + identity read | Live |
| Infra security | NSG, SSH-key-only, tfstate/secrets gitignored, OIDC | Live |
| Deployments | gitops/base/deployment.yaml | Live |
| Services | gitops/base/service.yaml (LoadBalancer) | Live |
| ConfigMaps/Secrets | gitops/base/configmap.yaml + secret.yaml | Live |
| HPA | gitops/base/hpa.yaml + /burn load test | Live |
| Ingress | gitops/base/ingress.yaml (Traefik) | Live |
| Docker | app/Dockerfile multi-stage/distroless + Trivy | Live |
| K8s governance | RBAC, NetworkPolicy, PDB, ResourceQuota | Live |
| Terraform (IaC) | infra/terraform/ + remote state | Live |
| Ansible (config) | infra/ansible/ idempotent roles | Live |
| Argo CD / GitOps | gitops/argocd/ auto staging, manual prod | Live |
| LoadBalancer | Service LB live; Azure LB designed | Live/Designed |
| Elasticity | HPA live; VMSS+autoscaler designed | Live/Designed |
| Cost optimization | cost.tf budget + auto-shutdown + tags | Live |
| Monitoring | Prometheus/Grafana + Azure Monitor | Live |

## Live vs Designed-and-Next (the lead signal)

Live/provisioned: everything marked Live above.

Designed, documented, deliberately not built (to control 24h scope + cost):
node-level autoscaling (VMSS + Cluster Autoscaler), Azure Load Balancer +
App Gateway for multi-node, AKS migration path, TLS via cert-manager,
external-secrets operator for automatic Key Vault sync.

Knowing what to cut and defending it is the lead competency.
