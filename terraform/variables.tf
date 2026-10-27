variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1"  # Frankfurt - closest to Hungary
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "vpc-api"
}

variable "cognito_domain_prefix" {
  description = "Cognito domain prefix (must be globally unique)"
  type        = string
  default     = "vpc-api"
}

variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.9"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 900
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}

variable "use_localstack" {
  description = "Whether to use LocalStack endpoints"
  type        = bool
  default     = false
}
