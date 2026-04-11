variable "project_name" {
  description = "Name of the project"
  type = string
}

variable "environment" {
  description = "Deployment environment"
  type = string

  validation {
    condition = contains(["dev", "staging", "prod"],var.environment)
    error_message = "Environment name must be either of dev, staging or prod"
  }
}

variable "vpc_id" {
  description = "VPC ID where MWAA environment will be deployed"
  type = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for MWAA environment"
  type = list(string)
}

variable "mwaa_execution_role_arn" {
  description = "ARN of the IAM execution role for the MWAA environment"
  type = string
}

variable "airflow_version" {
  description = "Version of Apache Airflow to use"
  type = string
  default = "2.8.1"
}

variable "environment_class" {
  description = "MWAA environment class (mw1.small for dev, mw1.medium for staging, mw1.large for prod)"
  type = string
  default = "mw1.small"
}

variable "min_workers" {
  description = "Minimum number of MWAA workers"
  type = number
  default = 1
}

variable "max_workers" {
  description = "Maximum number of MWAA workers"
  type = number
  default = 3
}

variable "tags" {
  description = "Additional key-value pair tags to be applied to all resources"
  type = map(string)
  default = {}
}