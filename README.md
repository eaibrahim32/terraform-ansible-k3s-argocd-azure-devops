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

<img width="1024" height="220" alt="image" src="https://github.com/user-attachments/assets/51030bb2-ffd8-40fe-a499-8c2d96cf1bc2" />
<img width="1271" height="817" alt="image" src="https://github.com/user-attachments/assets/6102368d-6bcb-43c3-853b-92a0fb64064b" />
<img width="1919" height="950" alt="image" src="https://github.com/user-attachments/assets/6588cf63-af57-449a-b216-1d96f384edee" /><img width="488" height="440" alt="image" src="https://github.com/user-attachments/assets/3c54d235-581f-4330-baf1-d3b57c50b951" />
<img width="1898" height="964" alt="image" src="https://github.com/user-attachments/assets/1f967bcd-2262-4cfc-b4be-8ec15bf4f8ee" />
<img width="1469" height="928" alt="image" src="https://github.com/user-attachments/assets/9af8f961-d21c-4733-bc60-c526aa00837a" />
<img width="1913" height="266" alt="image" src="https://github.com/user-attachments/assets/833fca2c-8d5b-4deb-a663-e20f57d26f7c" />
<img width="1920" height="224" alt="image" src="https://github.com/user-attachments/assets/e1fce6c6-9bde-4827-96a2-889f1f298066" />
<img width="1033" height="497" alt="image" src="https://github.com/user-attachments/assets/fb897d3c-33d9-43f1-9912-f96af07b42b6" />
<img width="1640" height="847" alt="image" src="https://github.com/user-attachments/assets/9e8e584a-997c-4d67-9ff4-024ee33f80eb" />
<img width="1606" height="865" alt="image" src="https://github.com/user-attachments/assets/435654ac-c427-4880-8e99-11d78ac9eabd" />
<img width="1888" height="834" alt="image" src="https://github.com/user-attachments/assets/5ccce341-eda2-4a13-82d0-08ce26ffac18" />











