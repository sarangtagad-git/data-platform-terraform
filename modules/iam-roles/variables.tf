variable "project_name" {
  description = "Name of the project used for naming and tagging resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be dev, staging or prod."
  }
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "github_org" {
  description = "GitHub organisation name for OIDC trust policy"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name for OIDC trust policy"
  type        = string
}

variable "tags" {
  description = "Additional key-value tags to apply to all resources"
  type        = map(string)
  default     = {}
}
