variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be either dev, staging, or prod"
  }
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster to monitor"
  type        = string
}

variable "alarm_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
}

variable "mwaa_environment_name" {
  description = "Name of the MWAA Airflow environment to monitor"
  type        = string
}

variable "dags_bucket_name" {
  description = "Name of the S3 bucket storing Airflow DAG files"
  type        = string
}

variable "data_lake_bucket_name" {
  description = "Name of the S3 data lake bucket to monitor"
  type        = string
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization percentage threshold to trigger alarm"
  type        = number
  default     = 80
}

variable "memory_alarm_threshold" {
  description = "Memory utilization percentage threshold to trigger alarm"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Additional key-value pair tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
