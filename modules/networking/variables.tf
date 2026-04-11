variable "project_name" {
  description = "Please provide project name"
  type = string
}

variable "environment" {
  description = "Deployment Environment"
  type = string
  
  validation {
    condition = contains(["dev","staging","prod"], var.environment)
    error_message = "The environment must be dev, staging, prod"
  }
}

variable "vpc_cidr" {
  description = "IP range for your entire VPC"
  type = string
  
  validation {
    condition = can(cidrhost(var.vpc_cidr,0))
    error_message = "vpc_cidr must be a valid CIDR block e.g. 10.0.0.0/16"
  }
}

variable "availability_zones" {
  description = "List of AZ to deploy into"
  type = list(string)
}

variable "public_subnet_cidrs" {
  description = "IP range of your public subnets"
  type = list(string)
}

variable "private_subnet_cidrs" {
  description = "IP range of your private subnets"
  type = list(string)
}

variable "enable_nat_gateway" {
  description = "Toggle NAT Gateway ON/OFF"
  type = bool
  default = true
}

variable "single_nat_gateway" {
  description = "Weather to have 1 NAT Gateway across all AZs means true OR 1 NAT Gateway per AZs means false"
  type = bool
  default = false
}

variable "enable_flow_logs" {
  description = "Toggle VPC flow logs. Capture all network traffic. Required for security auditing"
  type = bool
  default = true #security auditing by default
}

variable "tags" {
  description = "key-value pair of tags to be added to resources"
  type = map(string)
  default = {}
}

