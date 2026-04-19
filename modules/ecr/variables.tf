variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "tags" {
  description = "Additional key-value pair tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
