variable "bucket_name" {
  description = "Name of the main S3 bucket"
  type        = string
  default     = "security-lab-data-bucket"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
  validation {
    condition = contains(
      ["development", "staging", "production"], var.environment
    )
    error_message = "Must be development, staging, or production."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
