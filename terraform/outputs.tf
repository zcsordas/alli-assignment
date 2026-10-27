output "api_endpoint" {
  description = "API endpoint"
  value       = "http://localhost:4566/prod"
}

output "rest_api_id" {
  description = "API Gateway Rest API ID"
  value       = module.api_gateway.rest_api_id
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.dynamodb.table_name
}

output "lambda_function_arns" {
  description = "ARNs of the Lambda functions"
  value = {
    create_vpc = module.lambda_create_vpc.function_arn
    get_vpc    = module.lambda_get_vpc.function_arn
    list_vpcs  = module.lambda_list_vpcs.function_arn
    delete_vpc = module.lambda_delete_vpc.function_arn
  }
}
