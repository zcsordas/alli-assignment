# /vpc resource
resource "aws_api_gateway_resource" "vpc" {
  rest_api_id = module.api_gateway.rest_api_id
  parent_id   = module.api_gateway.root_resource_id
  path_part   = "vpc"
}

# /vpc/{vpc_id} resource
resource "aws_api_gateway_resource" "vpc_id" {
  rest_api_id = module.api_gateway.rest_api_id
  parent_id   = aws_api_gateway_resource.vpc.id
  path_part   = "{vpc_id}"
}

# /vpcs resource
resource "aws_api_gateway_resource" "vpcs" {
  rest_api_id = module.api_gateway.rest_api_id
  parent_id   = module.api_gateway.root_resource_id
  path_part   = "vpcs"
}

# POST /vpc - Create VPC
resource "aws_api_gateway_method" "create_vpc" {
  rest_api_id   = module.api_gateway.rest_api_id
  resource_id   = aws_api_gateway_resource.vpc.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create_vpc" {
  rest_api_id             = module.api_gateway.rest_api_id
  resource_id             = aws_api_gateway_resource.vpc.id
  http_method             = aws_api_gateway_method.create_vpc.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_create_vpc.function_arn
}

# GET /vpc/{vpc_id} - Get VPC
resource "aws_api_gateway_method" "get_vpc" {
  rest_api_id   = module.api_gateway.rest_api_id
  resource_id   = aws_api_gateway_resource.vpc_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_vpc" {
  rest_api_id             = module.api_gateway.rest_api_id
  resource_id             = aws_api_gateway_resource.vpc_id.id
  http_method             = aws_api_gateway_method.get_vpc.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_get_vpc.function_arn
}

# DELETE /vpc/{vpc_id} - Delete VPC
resource "aws_api_gateway_method" "delete_vpc" {
  rest_api_id   = module.api_gateway.rest_api_id
  resource_id   = aws_api_gateway_resource.vpc_id.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "delete_vpc" {
  rest_api_id             = module.api_gateway.rest_api_id
  resource_id             = aws_api_gateway_resource.vpc_id.id
  http_method             = aws_api_gateway_method.delete_vpc.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_delete_vpc.function_arn
}

# GET /vpcs - List VPCs
resource "aws_api_gateway_method" "list_vpcs" {
  rest_api_id   = module.api_gateway.rest_api_id
  resource_id   = aws_api_gateway_resource.vpcs.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "list_vpcs" {
  rest_api_id             = module.api_gateway.rest_api_id
  resource_id             = aws_api_gateway_resource.vpcs.id
  http_method             = aws_api_gateway_method.list_vpcs.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_list_vpcs.function_arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = module.api_gateway.rest_api_id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.vpc.id,
      aws_api_gateway_resource.vpc_id.id,
      aws_api_gateway_resource.vpcs.id,
      aws_api_gateway_method.create_vpc.id,
      aws_api_gateway_method.get_vpc.id,
      aws_api_gateway_method.delete_vpc.id,
      aws_api_gateway_method.list_vpcs.id,
      aws_api_gateway_integration.create_vpc.id,
      aws_api_gateway_integration.get_vpc.id,
      aws_api_gateway_integration.delete_vpc.id,
      aws_api_gateway_integration.list_vpcs.id,
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.create_vpc,
    aws_api_gateway_integration.get_vpc,
    aws_api_gateway_integration.delete_vpc,
    aws_api_gateway_integration.list_vpcs,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = module.api_gateway.rest_api_id
  stage_name    = "prod"
}
