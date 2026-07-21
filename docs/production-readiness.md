# Production-Readiness Gap Analysis

An honest account of where this build is production-shaped versus production-grade,
why each gap exists, and how I'd close it. A lead is judged on knowing the limits
of their own system, not on pretending a demo is production.

## 1. Built and working (demonstrable)
- IaC: Terraform provisions RG, VNet, NSG, VM, ACR, Key Vault, Log Analytics, managed identity, budget, auto-shutdown. Remote state in Azure Storage.
- Config mgmt: Ansible installs k3s, Helm, Argo CD, Trivy idempotently.
- GitOps: Argo CD auto-syncs staging, manual prod. Verified commit-to-rollout.
- Container security: multi-stage image, non-root, Trivy gate in CI.
- Identity: VM managed identity pulls from Key Vault + ACR; OIDC for CI. No creds in code.
- K8s governance: RBAC, default-deny NetworkPolicy, PDB, ResourceQuota, requests/limits, probes.
- Elasticity: HPA scaled 1->3 under CPU load, back to 1 when idle.
- Observability: Prometheus/Grafana in-cluster; Azure Monitor + CPU alert on host.

## 2. Gaps and remediation
- **No HA (single node):** node failure = outage. Fix: AKS multi-node or VMSS-backed k3s across zones.
- **App resilience:** under load, CPU-bound endpoint starved the readiness probe -> pods flapped -> HPA thrashed. Fix: right-size gunicorn workers, dedicated health-check thread, probes tuned to measured latency.
- **Manual live patches:** used kubectl patch during demo (diverges from Git). Fix: all changes via PR; keep auto-sync + self-heal on so drift reverts.
- **Image distribution:** built on node + imported with imagePullPolicy Never. Why: trial blocked ACR Tasks. Fix: CI builds/pushes to ACR, pods pull via AcrPull identity.
- **Secret delivery semi-manual:** Key Vault -> Secret is a manual step. Fix: external-secrets operator or Key Vault CSI driver for auto-sync + rotation.
- **No TLS:** HTTP only, no hostname. Fix: cert-manager + Let's Encrypt, real DNS, control-plane UIs via SSH tunnel only.
- **LoadBalancer node-local:** klipper serves on node IP, EXTERNAL-IP pending. Fix: real Azure LB + App Gateway (L7/WAF) on AKS.
- **No node autoscaling:** HPA scales pods only. Fix: VMSS + Cluster Autoscaler.
- **CI not run end-to-end:** pipeline written, not executed (trial registry limits). Fix: run against non-trial subscription with OIDC secrets.
- **Ansible compat:** stdout_callback=yaml removed in community.general 12.0; changed to result_format=yaml.

## 3. Environmental issues handled (judgment, not flaws)
- B-series VMs blocked across 3 regions (trial capacity) -> changed one variable (vm_size -> D2s_v5). Why vm_size is parameterized.
- ACR Tasks blocked on trial -> node-side build + k3s import.
- Cloud Shell token timeouts + total session resets -> recovered each time; rebuilt SSH access by extracting the key from Terraform remote state.
- Auto-shutdown fired mid-session -> cost control working as designed; disabled during active work.

## 4. One-line honest summary
A production-shaped GitOps platform: the patterns (IaC, config mgmt, GitOps, image
scanning, managed-identity secrets, K8s governance, observability) are real and
working. It is not production-grade: single node, the demo app needs load-hardening,
and a few steps are manual to work around free-trial limits. I can show exactly
where each gap is and how I'd close it — and knowing that boundary is the point.
