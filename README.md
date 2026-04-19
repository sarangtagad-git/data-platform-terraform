# Data Platform — Terraform Infrastructure

A production-grade AWS data platform built with Terraform, deployed via GitHub Actions CI/CD. Designed to demonstrate Staff-level data platform engineering across infrastructure, orchestration, security, and observability.

---

## Stack

| Layer | Technology |
|---|---|
| Cloud | AWS (ap-south-1) |
| IaC | Terraform |
| CI/CD | GitHub Actions (OIDC — no static keys) |
| Orchestration | Apache Airflow (AWS MWAA v3.0.6) |
| Containers | Amazon EKS v1.32 |
| Storage | Amazon S3 |
| Monitoring | CloudWatch + SNS |

---

## Architecture

![Architecture](architecture-diagram.html)

**Key design decisions:**
- All infrastructure provisioned as code — nothing created manually in console
- OIDC-based authentication for GitHub Actions — no static AWS credentials stored
- Least-privilege IAM — each service has its own scoped role
- IRSA (IAM Roles for Service Accounts) — EKS pods get temporary AWS credentials via OIDC token exchange, no hardcoded keys inside containers
- Private subnets for EKS and MWAA — no direct internet exposure
- Single NAT Gateway for dev, extendable to per-AZ for production

---

## Folder Structure

```
data-platform-terraform/
│
├── .github/
│   └── workflows/
│       └── terraform.yml          # CI/CD pipeline (plan / apply / destroy)
│
├── environments/
│   ├── dev/                       # Active dev environment
│   │   ├── backend.tf             # S3 + DynamoDB remote state
│   │   ├── main.tf                # Root module — wires all modules together
│   │   ├── variables.tf           # Variable declarations
│   │   ├── outputs.tf             # Environment-level outputs
│   │   └── terraform.tfvars       # Dev-specific values
│   ├── staging/                   # Staging environment (backend only)
│   └── prod/                      # Production environment (backend only)
│
├── modules/
│   ├── networking/                # VPC, subnets, IGW, NAT GW, route tables
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── locals.tf
│   │   └── data.tf
│   │
│   ├── iam-roles/                 # EKS roles, MWAA role, GitHub Actions OIDC role
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── locals.tf
│   │   └── data.tf
│   │
│   ├── s3-data-lake/              # Data lake bucket with versioning + lifecycle rules
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── locals.tf
│   │   └── data.tf
│   │
│   ├── eks/                       # EKS cluster + node groups + add-ons
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── locals.tf
│   │   └── data.tf
│   │
│   ├── airflow/                   # MWAA environment + DAGs S3 bucket + security group
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── locals.tf
│   │   └── data.tf
│   │
│   └── monitoring/                # CloudWatch dashboard + alarms + SNS alerts
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── locals.tf
│       └── data.tf
│
│   ├── ecr/                       # ECR repository for EKS task container images
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── locals.tf
│   │
│   └── secrets/                   # Secrets Manager — EKS kubeconfig for MWAA
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── locals.tf
│
├── kubernetes/
│   └── airflow-rbac.yaml          # K8s Namespace + Role + RoleBinding + IRSA ServiceAccount for MWAA pods
│
├── scripts/
│   ├── upload_dag.py              # Upload DAG files to S3
│   └── validate_dag.py            # Validate DAG syntax before upload
│
└── architecture-diagram.html      # Full infrastructure architecture diagram
```

---

## Modules

### `networking`
- VPC with CIDR `10.0.0.0/16`
- 3 public subnets + 3 private subnets across AZs (ap-south-1a/b/c)
- Internet Gateway for public subnets
- NAT Gateway for private subnet outbound traffic
- S3 VPC Endpoint for private S3 access without NAT
- VPC Flow Logs for network visibility

### `iam-roles`
- EKS Cluster Role — `AmazonEKSClusterPolicy`
- EKS Node Group Role — worker node + CNI + ECR policies
- MWAA Execution Role — S3, CloudWatch, SQS, KMS, Secrets Manager (least privilege inline policy)
- GitHub Actions OIDC Role — allows keyless authentication from GitHub Actions
- ETL Pod Role (IRSA) — scoped S3 write access for the `etl-job` pod; assumed via OIDC token exchange (no credentials stored in the container)

### `s3-data-lake`
- Versioning enabled
- Server-side encryption (AES-256)
- Lifecycle rules — transition to Glacier after 90 days, expire raw data after 364 days
- Public access fully blocked

### `eks`
- EKS v1.32 cluster
- Primary node group — `t3.small`, 1–3 nodes
- Secondary node group — `t3.medium`, 1–2 nodes
- Add-ons — `coredns`, `vpc-cni`, `kube-proxy`
- OIDC provider — prerequisite for IRSA; allows pods to exchange Kubernetes tokens for temporary AWS credentials
- EKS Access Entry for MWAA — maps MWAA IAM role to Kubernetes username `mwaa-user` (no aws-auth ConfigMap editing required)

### `airflow`
- AWS MWAA v3.0.6 — `mw1.small`
- DAGs S3 bucket with versioning
- Workers auto-scale 1–3 based on task queue depth
- Self-referencing security group for worker communication
- Webserver access mode: `PUBLIC_ONLY` (IAM auth protected)
- `apache-airflow-providers-cncf-kubernetes` installed via `requirements.txt` for `KubernetesPodOperator` support

### `ecr`
- ECR repository for EKS task container images (`etl-job`)
- Image scanning on push — detects vulnerabilities automatically
- Lifecycle policy — keeps last 10 images, auto-expires older ones

### `secrets`
- Stores EKS kubeconfig in AWS Secrets Manager
- MWAA workers read this at runtime to authenticate with EKS
- Kubeconfig uses exec-based token auth (`aws eks get-token`) — no static credentials

### `monitoring`
- CloudWatch dashboard — MWAA heartbeat, EKS CPU, S3 errors
- Alarms — MWAA SchedulerHeartbeat, EKS CPU > 90%, S3 4xx errors
- SNS topic with email subscription for alert notifications

---

## CI/CD Pipeline

```
Pull Request  →  terraform init + fmt + validate + plan  (comment on PR)
Push to main  →  terraform apply
workflow_dispatch  →  apply or destroy (manual trigger)
```

**Authentication:** GitHub OIDC — no AWS access keys stored in GitHub secrets. GitHub Actions assumes an IAM role via a short-lived OIDC token (2-hour session).

---

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured
- S3 bucket and DynamoDB table for remote state (bootstrap manually once)
- GitHub repository secret: `AWS_ACCOUNT_ID`

---

## Deploy

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

Or push to `main` branch — GitHub Actions handles it automatically.

---

## Destroy

```bash
# Via GitHub Actions (recommended)
# Go to Actions → Terraform CI/CD → Run workflow → select "destroy"

# Or locally
cd environments/dev
terraform destroy
```
