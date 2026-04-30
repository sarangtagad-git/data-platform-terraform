# General
project_name = "data-platform"
environment  = "prod"
aws_region   = "ap-south-1"

# Networking
# CIDR range: 10.2.0.0/16 — intentionally non-overlapping with dev (10.0) and staging (10.1)
# Allows VPC peering between environments without address conflicts
vpc_cidr             = "10.2.0.0/16"
availability_zones   = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnet_cidrs = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
enable_nat_gateway   = true
single_nat_gateway   = false  # one NAT gateway per AZ — if one AZ fails, other AZs still have egress
enable_flow_logs     = true

# EKS
# Production-grade instances — t3.large primary, m5.large secondary for memory-intensive workloads
admin_iam_arn   = "arn:aws:iam::699651639348:user/terraform-admin"
cluster_version = "1.32"
node_groups = {
  primary = {
    instance_type = "t3.large"
    desired_size  = 3
    min_size      = 2
    max_size      = 10
  }
  secondary = {
    instance_type = "m5.large"
    desired_size  = 2
    min_size      = 1
    max_size      = 5
  }
}

# Airflow
airflow_version   = "3.0.6"
environment_class = "mw1.large"  # largest class for production DAG throughput
min_workers       = 3
max_workers       = 10

# Monitoring
# Tightest thresholds — prod alerts fire at 70% to give headroom before saturation
alarm_email            = "sarangtagad@gmail.com"
cpu_alarm_threshold    = 70
memory_alarm_threshold = 70

# Tags
tags = {
  Owner      = "Sarang Tagad"
  Team       = "data-platform"
  CostCenter = "data-engineering"
}
