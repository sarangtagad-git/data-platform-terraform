# =============================================================================
# Networking Outputs
# =============================================================================
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnet_ids
}

# =============================================================================
# EKS Outputs
# =============================================================================
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "API server endpoint URL of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_ca_certificate" {
  description = "Base64 encoded certificate authority data for the EKS cluster"
  value       = module.eks.cluster_ca_certificate
}

# =============================================================================
# Airflow Outputs
# =============================================================================
output "airflow_environment_arn" {
  description = "ARN of the MWAA Airflow environment"
  value       = module.airflow.mwaa_environment_arn
}

output "airflow_webserver_url" {
  description = "URL of the Airflow web UI"
  value       = module.airflow.mwaa_webserver_url
}

output "dags_bucket_arn" {
  description = "ARN of the S3 bucket storing Airflow DAG files"
  value       = module.airflow.dags_bucket_arn
}

# =============================================================================
# S3 Data Lake Outputs
# =============================================================================
output "data_lake_bucket_name" {
  description = "Name of the S3 data lake bucket"
  value       = module.s3_data_lake.bucket_name
}

output "data_lake_bucket_arn" {
  description = "ARN of the S3 data lake bucket"
  value       = module.s3_data_lake.bucket_arn
}

# =============================================================================
# Monitoring Outputs
# =============================================================================
output "sns_topic_arn" {
  description = "ARN of the SNS topic used for alarm notifications"
  value       = module.monitoring.sns_topic_arn
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard in AWS console"
  value       = module.monitoring.cloudwatch_dashboard_url
}
