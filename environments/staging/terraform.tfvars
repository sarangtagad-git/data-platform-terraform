# General
project_name = "data-platform"
environment  = "staging"
aws_region   = "ap-south-1"

# Networking
# CIDR range: 10.1.0.0/16 — intentionally non-overlapping with dev (10.0) and prod (10.2)
# Allows VPC peering between environments without address conflicts
vpc_cidr             = "10.1.0.0/16"
availability_zones   = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
enable_nat_gateway   = true
single_nat_gateway   = true  # single NAT is acceptable for staging (not production traffic)
enable_flow_logs     = true

# EKS
# Medium instances — larger than dev to catch sizing issues before prod
admin_iam_arn   = "arn:aws:iam::699651639348:user/terraform-admin"
cluster_version = "1.32"
node_groups = {
  primary = {
    instance_type = "t3.medium"
    desired_size  = 2
    min_size      = 1
    max_size      = 5
  }
  secondary = {
    instance_type = "t3.large"
    desired_size  = 1
    min_size      = 1
    max_size      = 3
  }
}

# Airflow
airflow_version   = "3.0.6"
environment_class = "mw1.medium"  # upgrade from dev's mw1.small
min_workers       = 2
max_workers       = 5

# Monitoring
# Tighter thresholds than dev — alert earlier to catch issues before prod promotion
alarm_email            = "sarangtagad@gmail.com"
cpu_alarm_threshold    = 80
memory_alarm_threshold = 80

# Tags
tags = {
  Owner      = "Sarang Tagad"
  Team       = "data-platform"
  CostCenter = "data-engineering"
}
