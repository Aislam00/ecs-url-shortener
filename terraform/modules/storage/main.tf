resource "aws_kms_key" "dynamodb" {
  description         = "KMS key for DynamoDB encryption"
  enable_key_rotation = true
  tags                = var.tags
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${var.name_prefix}-dynamodb"
  target_key_id = aws_kms_key.dynamodb.key_id
}

resource "aws_dynamodb_table" "urls" {
  name         = "${var.name_prefix}-urls"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "short_code"

  attribute {
    name = "short_code"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-urls"
  })
}
