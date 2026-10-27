# IAM Module
module "iam" {
  source        = "./modules/iam"
  project_name  = var.project_name
  dynamodb_table_arn = module.dynamodb.table_arn
}

# DynamoDB Module
module "dynamodb" {
  source     = "./modules/dynamodb"
  table_name = "${var.project_name}-vpc-metadata"
}

# Archive files for Lambda functions
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

# Lambda Functions
module "lambda_create_vpc" {
  source             = "./modules/lambda"
  function_name      = "CreateVpcFunction"
  role_arn           = module.iam.lambda_role_arn
  handler            = "create_vpc.handler"
  filename           = data.archive_file.lambda_create_vpc.output_path
  source_code_hash   = data.archive_file.lambda_create_vpc.output_base64sha256
  runtime            = var.lambda_runtime
  timeout            = var.lambda_timeout
  memory_size        = var.lambda_memory_size
  environment_variables = {
    VPC_TABLE_NAME = module.dynamodb.table_name
    REGION         = var.aws_region
  }
}

module "lambda_get_vpc" {
  source             = "./modules/lambda"
  function_name      = "GetVpcFunction"
  role_arn           = module.iam.lambda_role_arn
  handler            = "get_vpc.handler"
  filename           = data.archive_file.lambda_get_vpc.output_path
  source_code_hash   = data.archive_file.lambda_get_vpc.output_base64sha256
  runtime            = var.lambda_runtime
  timeout            = var.lambda_timeout
  memory_size        = var.lambda_memory_size
  environment_variables = {
    VPC_TABLE_NAME = module.dynamodb.table_name
    REGION         = var.aws_region
  }
}

module "lambda_list_vpcs" {
  source             = "./modules/lambda"
  function_name      = "ListVpcsFunction"
  role_arn           = module.iam.lambda_role_arn
  handler            = "list_vpcs.handler"
  filename           = data.archive_file.lambda_list_vpcs.output_path
  source_code_hash   = data.archive_file.lambda_list_vpcs.output_base64sha256
  runtime            = var.lambda_runtime
  timeout            = var.lambda_timeout
  memory_size        = var.lambda_memory_size
  environment_variables = {
    VPC_TABLE_NAME = module.dynamodb.table_name
    REGION         = var.aws_region
  }
}

module "lambda_delete_vpc" {
  source             = "./modules/lambda"
  function_name      = "DeleteVpcFunction"
  role_arn           = module.iam.lambda_role_arn
  handler            = "delete_vpc.handler"
  filename           = data.archive_file.lambda_delete_vpc.output_path
  source_code_hash   = data.archive_file.lambda_delete_vpc.output_base64sha256
  runtime            = var.lambda_runtime
  timeout            = var.lambda_timeout
  memory_size        = var.lambda_memory_size
  environment_variables = {
    VPC_TABLE_NAME = module.dynamodb.table_name
    REGION         = var.aws_region
  }
}

# API Gateway Module
module "api_gateway" {
  source         = "./modules/api_gateway"
  project_name   = var.project_name
  aws_region     = var.aws_region
  lambda_functions = {
    create_vpc = { function_name = module.lambda_create_vpc.function_name }
    get_vpc    = { function_name = module.lambda_get_vpc.function_name }
    list_vpcs  = { function_name = module.lambda_list_vpcs.function_name }
    delete_vpc = { function_name = module.lambda_delete_vpc.function_name }
  }
}
