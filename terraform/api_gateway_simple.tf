# Simplified API Gateway for LocalStack - NO AUTHENTICATION

# API Gateway REST API
resource "aws_api_gateway_rest_api" "main_simple" {
  name        = "${var.project_name}-api-simple"
  description = "VPC Management API without authentication (LocalStack)"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# /vpc resource
resource "aws_api_gateway_resource" "vpc_simple" {
  rest_api_id = aws_api_gateway_rest_api.main_simple.id
  parent_id   = aws_api_gateway_rest_api.main_simple.root_resource_id
  path_part   = "vpc"
}

# /vpc/{vpc_id} resource
resource "aws_api_gateway_resource" "vpc_id_simple" {
  rest_api_id = aws_api_gateway_rest_api.main_simple.id
  parent_id   = aws_api_gateway_resource.vpc_simple.id
  path_part   = "{vpc_id}"
}

# /vpcs resource
resource "aws_api_gateway_resource" "vpcs_simple" {
  rest_api_id = aws_api_gateway_rest_api.main_simple.id
  parent_id   = aws_api_gateway_rest_api.main_simple.root_resource_id
  path_part   = "vpcs"
}

# POST /vpc - Create VPC (NO AUTH)
resource "aws_api_gateway_method" "create_vpc_simple" {
  rest_api_id   = aws_api_gateway_rest_api.main_simple.id
  resource_id   = aws_api_gateway_resource.vpc_simple.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create_vpc_simple" {
  rest_api_id             = aws_api_gateway_rest_api.main_simple.id
  resource_id             = aws_api_gateway_resource.vpc_simple.id
  http_method             = aws_api_gateway_method.create_vpc_simple.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_vpc.invoke_arn
}

# GET /vpc/{vpc_id} - Get VPC (NO AUTH)
resource "aws_api_gateway_method" "get_vpc_simple" {
  rest_api_id   = aws_api_gateway_rest_api.main_simple.id
  resource_id   = aws_api_gateway_resource.vpc_id_simple.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_vpc_simple" {
  rest_api_id             = aws_api_gateway_rest_api.main_simple.id
  resource_id             = aws_api_gateway_resource.vpc_id_simple.id
  http_method             = aws_api_gateway_method.get_vpc_simple.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_vpc.invoke_arn
}

# DELETE /vpc/{vpc_id} - Delete VPC (NO AUTH)
resource "aws_api_gateway_method" "delete_vpc_simple" {
  rest_api_id   = aws_api_gateway_rest_api.main_simple.id
  resource_id   = aws_api_gateway_resource.vpc_id_simple.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "delete_vpc_simple" {
  rest_api_id             = aws_api_gateway_rest_api.main_simple.id
  resource_id             = aws_api_gateway_resource.vpc_id_simple.id
  http_method             = aws_api_gateway_method.delete_vpc_simple.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.delete_vpc.invoke_arn
}

# GET /vpcs - List VPCs (NO AUTH)
resource "aws_api_gateway_method" "list_vpcs_simple" {
  rest_api_id   = aws_api_gateway_rest_api.main_simple.id
  resource_id   = aws_api_gateway_resource.vpcs_simple.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "list_vpcs_simple" {
  rest_api_id             = aws_api_gateway_rest_api.main_simple.id
  resource_id             = aws_api_gateway_resource.vpcs_simple.id
  http_method             = aws_api_gateway_method.list_vpcs_simple.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_vpcs.invoke_arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main_simple" {
  rest_api_id = aws_api_gateway_rest_api.main_simple.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.vpc_simple.id,
      aws_api_gateway_resource.vpc_id_simple.id,
      aws_api_gateway_resource.vpcs_simple.id,
      aws_api_gateway_method.create_vpc_simple.id,
      aws_api_gateway_method.get_vpc_simple.id,
      aws_api_gateway_method.delete_vpc_simple.id,
      aws_api_gateway_method.list_vpcs_simple.id,
      aws_api_gateway_integration.create_vpc_simple.id,
      aws_api_gateway_integration.get_vpc_simple.id,
      aws_api_gateway_integration.delete_vpc_simple.id,
      aws_api_gateway_integration.list_vpcs_simple.id,
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.create_vpc_simple,
    aws_api_gateway_integration.get_vpc_simple,
    aws_api_gateway_integration.delete_vpc_simple,
    aws_api_gateway_integration.list_vpcs_simple,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "prod_simple" {
  deployment_id = aws_api_gateway_deployment.main_simple.id
  rest_api_id   = aws_api_gateway_rest_api.main_simple.id
  stage_name    = "prod"
}

# Lambda Permissions for API Gateway
resource "aws_lambda_permission" "create_vpc_simple" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_vpc.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main_simple.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_vpc_simple" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_vpc.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main_simple.execution_arn}/*/*"
}

resource "aws_lambda_permission" "list_vpcs_simple" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_vpcs.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main_simple.execution_arn}/*/*"
}

resource "aws_lambda_permission" "delete_vpc_simple" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_vpc.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main_simple.execution_arn}/*/*"
}

# Output
output "api_endpoint_localstack" {
  description = "LocalStack API endpoint (no auth required)"
  value       = "http://localhost:4566/restapis/${aws_api_gateway_rest_api.main_simple.id}/prod/_user_request_"
}
