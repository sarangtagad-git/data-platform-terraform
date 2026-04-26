variable "project_name" {
  description = "Name of the project"
  type = string
}

variable "environment" {
  description = "Deployment Environment"
  type = string

  validation {
    condition = contains(["dev","staging","prod"],var.environment)
    error_message = "Environment name must be either of dev, staging or prod"
  }
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be deployed to"
  type = string
}

variable "private_subnet_ids" {
  description = "ID of private subnet where EKS cluster will be deployed to"  
  type = list(string)
}

variable "cluster_version" {
  description = "What is your EKS version going to be"  
  type = string
  default = "1.32"
}

variable "node_groups" {
  description = "Map of node group configurations"
  type = map(object({
    instance_type = string
    desired_size  = number
    min_size      = number
    max_size      = number
  }))
  default = {
    primary = {
      instance_type = "t3.small"
      desired_size  = 2
      min_size      = 1
      max_size      = 3
    }
    secondary = {
      instance_type = "t3.medium"
      desired_size  = 1
      min_size      = 1
      max_size      = 2
    }
  }
}

variable "eks_cluster_role_arn" {
  description = "ARN of the IAM role to assign to the EKS cluster control plane"
  type = string
}

variable "eks_node_group_role_arn" {
  description = "ARN of the IAM role to assign to the EKS worker node group"
  type = string
}

variable "mwaa_role_arn" {
  description = "ARN of the MWAA execution IAM role — granted access to EKS cluster via access entry"
  type        = string
}

variable "admin_iam_arn" {
  description = "ARN of the IAM user or role that needs kubectl admin access to the cluster (e.g. local terraform-admin user)"
  type        = string
}

variable "github_actions_role_arn" {
  description = "ARN of the GitHub Actions OIDC IAM role — needs cluster admin access to apply Kubernetes resources via Terraform"
  type        = string
}

variable "tags" {
  description = "Additional key-value pair tags to be applied to all resources"
  type = map(string)
  default = {}
}
