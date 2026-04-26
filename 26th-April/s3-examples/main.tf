# S3 Bucket Configuration
# File: main.tf

resource "aws_s3_bucket" "app" {
  bucket = "my-app-bucket-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Application Bucket"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "app" {
  bucket = aws_s3_bucket.app.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "application-logs/"
}

resource "aws_s3_bucket" "logs" {
  bucket = "my-app-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Logging Bucket"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_caller_identity" "current" {}
