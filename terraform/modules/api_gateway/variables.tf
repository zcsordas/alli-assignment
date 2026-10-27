variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "lambda_functions" {
  description = "Map of lambda functions to grant API Gateway permission to invoke"
  type = map(object({
    function_name = string
  }))
}
