variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key used for DynamoDB encryption"
  type        = string
}
