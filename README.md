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

## Cost Optimization

This project's infrastructure cost about **$1.34** end-to-end on Azure — a full
Kubernetes cluster, container registry, Key Vault, monitoring, and networking —
then torn down to $0 ongoing cost.

Cost was a design decision, not an afterthought:

- **k3s instead of AKS** — no managed control-plane fee (AKS adds ~$73/month just for the control plane). A full, certified Kubernetes cluster ran on a single billable VM.
- **Single right-sized VM** — one burstable node instead of a multi-node cluster. The VM was the largest cost at ~$1.00.
- **Basic-tier services** — Container Registry Basic, Standard_LRS storage, standard Key Vault: the lowest tier that met the need.
- **Nightly auto-shutdown** — the VM powers off automatically so it never bills around the clock.
- **Budget + alerts** — a monthly budget with email alerts at 80% and 100% as a backstop.
- **terraform destroy when idle** — infrastructure is disposable and reproducible.

| Service | Cost |
|---|---|
| Virtual Machine (D2s_v5, ~10 hrs) | $1.00 |
| Container Registry (Basic) | $0.12 |
| Storage, networking, Key Vault, monitoring | $0.22 |
| **Project total** | **~$1.34** |

> Note: The Azure billing account shows a slightly higher total ($1.72) because it includes an unrelated Azure SQL Database charge from a separate resource on the same subscription. That SQL resource is **not part of this project** — this project provisions no database — so it is excluded from the cost above.
> <img width="1431" height="608" alt="image" src="https://github.com/user-attachments/assets/ffa8c62e-4712-4a0f-b31d-7095ffef9e44" />
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
<img width="1861" height="847" alt="image" src="https://github.com/user-attachments/assets/db84326c-7a29-4fa5-8f24-b32043e3193a" />
<img width="1887" height="590" alt="image" src="https://github.com/user-attachments/assets/6256f235-df1e-406c-86c9-476f0a383b50" />
<img width="1868" height="579" alt="image" src="https://github.com/user-attachments/assets/63edec0f-78ee-4a83-be5f-dc2eef64b046" />
<img width="1530" height="566" alt="image" src="https://github.com/user-attachments/assets/dab3f956-6ac8-449a-9f0f-fd789614ccee" />
<img width="1607" height="651" alt="image" src="https://github.com/user-attachments/assets/ec9c5a74-25cf-411b-bd54-6d1c455af745" />
<img width="1605" height="646" alt="image" src="https://github.com/user-attachments/assets/27a1363d-d0ca-4045-b713-d3dfad10fbb5" />
<img width="1884" height="842" alt="image" src="https://github.com/user-attachments/assets/37b1ccf6-1173-466a-9d2d-60a8723af126" />
<img width="1888" height="632" alt="image" src="https://github.com/user-attachments/assets/0825b225-4150-4495-9d5e-9f336fb3b7e0" />
<img width="1869" height="673" alt="image" src="https://github.com/user-attachments/assets/b14cfce0-91e0-4ac3-98fd-a2f9127e7033" />
<img width="1907" height="672" alt="image" src="https://github.com/user-attachments/assets/982eafab-083b-403c-82d9-08f01cd13ba6" />
<img width="1905" height="864" alt="image" src="https://github.com/user-attachments/assets/787d65cb-65c6-430d-a623-b2a77e04f2fc" />
<img width="1919" height="874" alt="image" src="https://github.com/user-attachments/assets/9051af7c-a3d1-44dd-a8ac-3459d9383ab9" />

## GitOps Deployment (Argo CD)

The application is deployed using GitOps. Argo CD watches the Git repository and automatically syncs the cluster to match it. Pushing a change to the manifests triggers a rollout — no manual `kubectl apply`. Staging auto-syncs; production is a manual sync.

## Autoscaling & Elasticity (HPA)

A HorizontalPodAutoscaler scales the app on CPU usage. Under load the deployment scaled from 1 to 3 pods, then back to 1 when load cleared — elasticity in both directions.

## Monitoring & Observability

Two layers:

**Cluster metrics — Prometheus + Grafana.** Prometheus scrapes and stores metrics from the cluster (nodes, pods, system components). Grafana queries Prometheus and displays the dashboards. Prometheus is the collector; Grafana is the visualizer.

**Host metrics — Azure Monitor.** The VM sends host metrics and logs to a Log Analytics workspace, with a CPU alert.

## Secrets Management (Key Vault + Managed Identity)

Secrets are never stored in code or config. The VM authenticates to Azure Key Vault using its managed identity (via IMDS) and reads the secret at runtime. The identity has a scoped, read-only Key Vault Secrets User role. No credentials anywhere.

## Cost Optimization

The entire platform cost about **$1.77** on Azure — a full Kubernetes cluster, container registry, Key Vault, monitoring, and networking — then torn down to $0 ongoing cost.

Cost was a design decision, not an afterthought:

- **k3s instead of AKS** — no managed control-plane fee (AKS adds ~$73/month just for the control plane).
- **Single right-sized VM** — one node instead of a multi-node cluster.
- **Basic-tier services** — Container Registry Basic, Standard_LRS storage, standard Key Vault.
- **Nightly auto-shutdown** — the VM powers off automatically so it never bills around the clock.
- **Budget + alerts** — a monthly budget with email alerts at 80% and 100%.
- **terraform destroy when idle** — infrastructure is disposable and reproducible.
