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

variable "bucket_name" {
  description = "Name of the S3 data lake bucket"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning to keep history of all file changes and allow recovery"
  type        = bool
  default     = true
}

variable "lifecycle_rules_enabled" {
  description = "Enable lifecycle rules to auto-archive old data and save storage costs"
  type        = bool
  default     = true
}

variable "raw_data_expiry_days" {
  description = "Number of days before raw data is moved to Glacier storage"
  type        = number
  default     = 365
}

variable "force_destroy" {
  description = "Allow Terraform to delete non-empty bucket. Set true only for dev — dangerous in prod!"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional key-value tags to apply to all resources"
  type        = map(string)
  default     = {}
}
