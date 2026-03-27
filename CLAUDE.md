# CLAUDE.md — Project context for Claude Code

## What this repo is
A portfolio Terraform project built to demonstrate Staff Data Platform Engineer skills
for a Zendesk interview. Repo: zendesk-data-platform-tf

## Stack (mirrors Zendesk's actual stack)
- Cloud: AWS (primary), GCP (secondary)
- IaC: Terraform
- Orchestration: Airflow (MWAA)
- Compute: EKS + Docker
- CI/CD: GitHub Actions

## Repo structure
- modules/      — reusable modules (networking, iam-roles, s3-data-lake, eks, airflow, monitoring)
- environments/ — dev / staging / prod (composition only, no logic)
- .github/workflows/ — terraform plan on PR, apply on merge

## Progress so far
- [x] Remote state: S3 bucket + DynamoDB lock table created in ap-south-1
- [ ] modules/s3-data-lake — build this first
- [ ] modules/networking
- [ ] modules/iam-roles
- [ ] modules/eks
- [ ] modules/airflow
- [ ] .github/workflows/terraform.yml

## Build order
networking → iam-roles → s3-data-lake → eks → airflow → monitoring

## Key decisions made
- State bucket: zendesk-tf-state-yourname, key per env (dev/terraform.tfstate etc)
- DynamoDB table: terraform-state-lock
- Region: ap-south-1
- No logic in environments/ — modules only
