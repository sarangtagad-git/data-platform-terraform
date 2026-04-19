terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# =============================================================================
# Networking
# Creates VPC, subnets, NAT gateway, route tables, flow logs, S3 VPC endpoint
# =============================================================================
module "networking" {
  source = "../../modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_flow_logs     = var.enable_flow_logs
  tags                 = var.tags
}

# =============================================================================
# IAM Roles
# Creates EKS cluster role, EKS node group role, MWAA execution role,
# and GitHub Actions OIDC role for keyless CI/CD authentication
# =============================================================================
module "iam_roles" {
  source = "../../modules/iam-roles"

  project_name     = var.project_name
  environment      = var.environment
  aws_region       = var.aws_region
  eks_cluster_name = "${var.project_name}-${var.environment}-eks"
  github_org       = "sarangtagad-git"
  github_repo      = "data-platform-terraform"
  tags             = var.tags
}

# =============================================================================
# S3 Data Lake
# Creates versioned S3 bucket with lifecycle rules and encryption
# force_destroy = true in dev only — allows clean terraform destroy
# =============================================================================
module "s3_data_lake" {
  source = "../../modules/s3-data-lake"

  project_name            = var.project_name
  environment             = var.environment
  bucket_name             = "${var.project_name}-${var.environment}-data-lake"
  force_destroy           = true
  enable_versioning       = true
  lifecycle_rules_enabled = true
  raw_data_expiry_days    = 364
  tags                    = var.tags
}

# =============================================================================
# EKS
# Creates EKS cluster, primary + secondary node groups, and core add-ons
# Depends on networking (VPC/subnets) and iam_roles outputs
# =============================================================================
module "eks" {
  source = "../../modules/eks"

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.networking.vpc_id
  private_subnet_ids      = module.networking.private_subnet_ids
  cluster_version         = var.cluster_version
  node_groups             = var.node_groups
  eks_cluster_role_arn    = module.iam_roles.eks_cluster_role_arn
  eks_node_group_role_arn = module.iam_roles.eks_node_group_role_arn
  mwaa_role_arn           = module.iam_roles.mwaa_role_arn
  tags                    = var.tags
}

# =============================================================================
# Airflow (MWAA)
# Creates MWAA environment, DAGs S3 bucket, and security group
# Depends on networking and iam_roles outputs
# =============================================================================
module "airflow" {
  source = "../../modules/airflow"

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.networking.vpc_id
  private_subnet_ids      = module.networking.private_subnet_ids
  mwaa_execution_role_arn = module.iam_roles.mwaa_role_arn
  airflow_version         = var.airflow_version
  environment_class       = var.environment_class
  min_workers             = var.min_workers
  max_workers             = var.max_workers
  tags                    = var.tags
}

# =============================================================================
# ECR
# Creates Docker image repository for EKS task containers (KubernetesPodOperator)
# =============================================================================
module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}

# =============================================================================
# Secrets
# Stores EKS kubeconfig in Secrets Manager so MWAA can authenticate to EKS
# =============================================================================
module "secrets" {
  source = "../../modules/secrets"

  project_name           = var.project_name
  environment            = var.environment
  aws_region             = var.aws_region
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate
  tags                   = var.tags
}

# =============================================================================
# Monitoring
# Creates SNS alerts, CloudWatch alarms, and dashboard
# Depends on eks, airflow, and s3 module outputs
# =============================================================================
module "monitoring" {
  source = "../../modules/monitoring"

  project_name           = var.project_name
  environment            = var.environment
  aws_region             = var.aws_region
  eks_cluster_name       = module.eks.cluster_name
  mwaa_environment_name  = "${var.project_name}-${var.environment}-airflow"
  dags_bucket_name       = "${var.project_name}-${var.environment}-airflow-dags"
  data_lake_bucket_name  = "${var.project_name}-${var.environment}-data-lake"
  alarm_email            = var.alarm_email
  cpu_alarm_threshold    = var.cpu_alarm_threshold
  memory_alarm_threshold = var.memory_alarm_threshold
  tags                   = var.tags
}
