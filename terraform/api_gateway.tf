# CloudWatch Log Group for API Gateway Access Logs
resource "aws_cloudwatch_log_group" "api_gateway_access_logs" {
  name              = "/aws/api-gateway/${var.project_name}-access-logs"
  retention_in_days = 7
}

# Enable API Gateway Access Logging for the account
resource "aws_api_gateway_account" "this" {
  cloudwatch_logs_role_arn = aws_iam_role.api_gateway_cloudwatch_logs.arn
}

# IAM Role for API Gateway to write to CloudWatch Logs
resource "aws_iam_role" "api_gateway_cloudwatch_logs" {
  name = "${var.project_name}-api-gateway-cloudwatch-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_logs_attachment" {
  role       = aws_iam_role.api_gateway_cloudwatch_logs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

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
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.lambda_create_vpc.function_arn}/invocations"
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
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.lambda_get_vpc.function_arn}/invocations"
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
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.lambda_delete_vpc.function_arn}/invocations"
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
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.lambda_list_vpcs.function_arn}/invocations"
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
