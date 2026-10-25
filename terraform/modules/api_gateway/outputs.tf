output "rest_api_id" {
  description = "The ID of the REST API"
  value       = aws_api_gateway_rest_api.this.id
}

output "execution_arn" {
  description = "The execution ARN of the REST API"
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "root_resource_id" {
  description = "The ID of the root resource"
  value       = aws_api_gateway_rest_api.this.root_resource_id
}
