# DynamoDB Table for VPC Metadata
resource "aws_dynamodb_table" "vpc_metadata" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "vpc_id"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "vpc_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  global_secondary_index {
    name            = "CreatedAtIndex"
    hash_key        = "created_at"
    projection_type = "ALL"
  }

  tags = {
    Name = "${var.table_name}-table"
  }
}
