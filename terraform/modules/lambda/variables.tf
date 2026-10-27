variable "function_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "role_arn" {
  description = "The ARN of the Lambda execution role"
  type        = string
}

variable "handler" {
  description = "The handler of the Lambda function"
  type        = string
}

variable "filename" {
  description = "The filename of the Lambda function zip"
  type        = string
}

variable "source_code_hash" {
  description = "The source code hash of the Lambda function"
  type        = string
}

variable "runtime" {
  description = "The runtime of the Lambda function"
  type        = string
  default     = "python3.9"
}

variable "timeout" {
  description = "The timeout of the Lambda function"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "The memory size of the Lambda function"
  type        = number
  default     = 128
}

variable "environment_variables" {
  description = "The environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}
