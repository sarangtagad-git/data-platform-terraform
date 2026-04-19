variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "aws_region" {
  description = "AWS region — used in kubeconfig exec command for token generation"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name — used in kubeconfig"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS API server endpoint URL — used in kubeconfig"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64 encoded EKS cluster certificate authority — used in kubeconfig"
  type        = string
}

variable "tags" {
  description = "Additional key-value pair tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
