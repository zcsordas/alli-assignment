variable "table_name" {
  description = "The name of the DynamoDB table"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key used for encryption"
  type        = string
}
