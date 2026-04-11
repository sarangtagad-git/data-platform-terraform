# CLAUDE.md — Project context for Claude Code

## What this repo is
A portfolio Terraform project built to demonstrate Staff Data Platform Engineer skills
for a Zendesk interview (Pune, Hybrid). Must demonstrate Staff-level complexity across
the full Zendesk stack.

## Zendesk Stack (mirrored in this project)
- Cloud: AWS (primary), GCP (secondary)
- IaC: Terraform (complex setups)
- Containers: EKS + Docker
- CI/CD: GitHub Actions
- Orchestration: Airflow (MWAA)
- Data: Snowflake, dbt, Fivetran (referenced in architecture)
- Monitoring: CloudWatch + DataDog (SLOs/SLIs)
- Language: Python (automation scripts)

## Skills this project must demonstrate (screening checklist)
- [x] Terraform with complex setups
- [ ] Kubernetes (EKS) + Docker
- [ ] CI/CD pipelines using GitHub Actions
- [ ] Python scripting for automation and tooling
- [ ] Monitoring (CloudWatch/DataDog) + SLOs/SLIs
- [ ] AWS hands-on
- [ ] Apache Airflow orchestration
- [ ] Reusable automation/self-healing tools
- [ ] Data governance and security best practices

## Repo structure
- modules/      — reusable modules (networking, iam-roles, s3-data-lake, eks, airflow, monitoring)
- environments/ — dev / staging / prod (composition only, no logic)
- .github/workflows/ — terraform plan on PR, apply on merge
- scripts/      — Python automation scripts
- docker/       — Dockerfiles for Airflow custom image

## Progress
- [x] Remote state: S3 bucket (data-platform-tf-state-sarang) + DynamoDB lock table (terraform-state-lock) created in ap-south-1 with encryption, versioning, and PITR enabled
- [x] environments/dev/backend.tf
- [x] environments/staging/backend.tf
- [x] environments/prod/backend.tf
- [x] modules/networking
- [x] modules/iam-roles
- [x] modules/s3-data-lake
- [ ] modules/eks
- [ ] modules/airflow
- [ ] modules/monitoring
- [ ] .github/workflows/terraform.yml
- [ ] scripts/ (Python automation)
- [ ] docker/ (Airflow custom image)

## Build order
networking → iam-roles → s3-data-lake → eks → airflow → monitoring → CI/CD → Python scripts

## Key decisions made
- State bucket: data-platform-tf-state-sarang, key per env (dev/terraform.tfstate etc)
- DynamoDB table: terraform-state-lock (encrypted + PITR enabled)
- Region: ap-south-1
- No logic in environments/ — modules only
- Multi-AZ design throughout for HA
