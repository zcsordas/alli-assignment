# Archive Lambda source code (no external dependencies needed - boto3 is built-in)
data "archive_file" "lambda_create_vpc" {
  type        = "zip"
  source_file = "${path.module}/../src/create_vpc.py"
  output_path = "${path.module}/.terraform/lambda/create_vpc.zip"
}

data "archive_file" "lambda_get_vpc" {
  type        = "zip"
  source_file = "${path.module}/../src/get_vpc.py"
  output_path = "${path.module}/.terraform/lambda/get_vpc.zip"
}

data "archive_file" "lambda_list_vpcs" {
  type        = "zip"
  source_file = "${path.module}/../src/list_vpcs.py"
  output_path = "${path.module}/.terraform/lambda/list_vpcs.zip"
}

data "archive_file" "lambda_delete_vpc" {
  type        = "zip"
  source_file = "${path.module}/../src/delete_vpc.py"
  output_path = "${path.module}/.terraform/lambda/delete_vpc.zip"
}

# Lambda Function: Create VPC
resource "aws_lambda_function" "create_vpc" {
  filename         = data.archive_file.lambda_create_vpc.output_path
  function_name    = "CreateVpcFunction"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "create_vpc.handler"
  source_code_hash = data.archive_file.lambda_create_vpc.output_base64sha256
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment {
    variables = {
      VPC_TABLE_NAME = aws_dynamodb_table.vpc_metadata.name
      REGION         = var.aws_region
    }
  }

  tags = {
    Name = "CreateVpcFunction"
  }
}

# Lambda Function: Get VPC
resource "aws_lambda_function" "get_vpc" {
  filename         = data.archive_file.lambda_get_vpc.output_path
  function_name    = "GetVpcFunction"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "get_vpc.handler"
  source_code_hash = data.archive_file.lambda_get_vpc.output_base64sha256
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment {
    variables = {
      VPC_TABLE_NAME = aws_dynamodb_table.vpc_metadata.name
      REGION         = var.aws_region
    }
  }

  tags = {
    Name = "GetVpcFunction"
  }
}

# Lambda Function: List VPCs
resource "aws_lambda_function" "list_vpcs" {
  filename         = data.archive_file.lambda_list_vpcs.output_path
  function_name    = "ListVpcsFunction"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "list_vpcs.handler"
  source_code_hash = data.archive_file.lambda_list_vpcs.output_base64sha256
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment {
    variables = {
      VPC_TABLE_NAME = aws_dynamodb_table.vpc_metadata.name
      REGION         = var.aws_region
    }
  }

  tags = {
    Name = "ListVpcsFunction"
  }
}

# Lambda Function: Delete VPC
resource "aws_lambda_function" "delete_vpc" {
  filename         = data.archive_file.lambda_delete_vpc.output_path
  function_name    = "DeleteVpcFunction"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "delete_vpc.handler"
  source_code_hash = data.archive_file.lambda_delete_vpc.output_base64sha256
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment {
    variables = {
      VPC_TABLE_NAME = aws_dynamodb_table.vpc_metadata.name
      REGION         = var.aws_region
    }
  }

  tags = {
    Name = "DeleteVpcFunction"
  }
}

# Lambda Permissions for API Gateway
# These are now defined in api_gateway_simple.tf for LocalStack
# Commented out to avoid duplicate permissions

# resource "aws_lambda_permission" "create_vpc" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.create_vpc.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
# }

# resource "aws_lambda_permission" "get_vpc" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.get_vpc.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
# }

# resource "aws_lambda_permission" "list_vpcs" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.list_vpcs.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
# }

# resource "aws_lambda_permission" "delete_vpc" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.delete_vpc.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
# }
