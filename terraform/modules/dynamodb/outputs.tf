output "table_arn" {
  description = "The ARN of the DynamoDB table"
  value       = aws_dynamodb_table.vpc_metadata.arn
}

output "table_name" {
  description = "The name of the DynamoDB table"
  value       = aws_dynamodb_table.vpc_metadata.name
}
