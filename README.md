# terraform-ansible-k3s-argocd-azure-devops

End-to-end, prod-shaped Azure platform for a DevOps Lead portfolio.
Terraform provisions, Ansible configures, Argo CD deploys. Staging + prod
environments, image security gating, observability, IAM/secrets via Azure
managed identity, and provisioned cost controls. Runs in Azure Cloud Shell.

## Layout
- app/                 Flask app + multi-stage distroless Dockerfile
- infra/terraform/     RG, VNet, NSG, VM, ACR, Key Vault, monitoring, budget
- infra/ansible/       idempotent roles: k3s, helm, Argo CD, Trivy
- gitops/base/         hardened k8s manifests
- gitops/overlays/     staging (auto) + prod (manual) via Kustomize
- gitops/argocd/       Argo CD project + Applications
- .github/workflows/   build -> Trivy gate -> ACR push -> GitOps bump
- docs/                ADR + requirement map

## Runbook (Cloud Shell)

### 1. Terraform
    cd infra/terraform
    terraform init
    cp terraform.tfvars.example terraform.tfvars   # set allowed_ssh_cidr + alert_email
    terraform apply
    terraform output

### 2. Ansible
    cd ../ansible
    cp inventory.ini.example inventory.ini          # paste VM public IP
    ansible-galaxy collection install ansible.posix community.general
    ansible-playbook playbook.yml

### 3. Secret from Key Vault (managed identity, no creds)
    SECRET=$(az keyvault secret show --vault-name <kv-name> --name app-secret --query value -o tsv)
    kubectl create namespace staging
    kubectl create secret generic app-secret -n staging --from-literal=APP_SECRET="$SECRET"

### 4. GitOps
    kubectl apply -f gitops/argocd/project.yaml
    kubectl apply -f gitops/argocd/app-staging.yaml
    kubectl apply -f gitops/argocd/app-prod.yaml

### 5. Verify (demo moments)
    kubectl get svc -n staging app
    curl http://<vm-ip>/
    kubectl get hpa -n staging -w &
    seq 1 200 | xargs -n1 -P20 -I{} curl -s http://<vm-ip>/burn >/dev/null
    kubectl delete deploy app -n staging   # Argo CD self-heals

Access Argo CD and Grafana via kubectl port-forward, never exposed publicly.

## Teardown
    cd infra/terraform && terraform destroy

## Security posture
- Distroless, non-root, read-only rootfs, dropped capabilities.
- Trivy gate fails builds on HIGH/CRITICAL CVEs.
- NSG least-privilege; Argo CD/Grafana never public.
- Key Vault + VM managed identity: zero secrets in code or git.
- GitHub Actions to Azure via OIDC, no stored cloud credentials.
- tfstate, keys, tfvars, inventory all gitignored.

See docs/architecture.md for the ADR and docs/requirement-map.md for the
requirement mapping and the live-vs-designed split.
