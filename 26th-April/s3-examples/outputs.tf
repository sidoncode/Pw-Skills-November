# Outputs
# File: outputs.tf

output "bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.app.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.app.arn
}

output "bucket_region" {
  description = "S3 bucket region"
  value       = aws_s3_bucket.app.region
}

output "bucket_domain_name" {
  description = "S3 bucket regional domain name"
  value       = aws_s3_bucket.app.bucket_regional_domain_name
}

output "log_bucket_id" {
  description = "Log bucket ID"
  value       = aws_s3_bucket.logs.id
}

output "versioning_enabled" {
  description = "Whether versioning is enabled"
  value       = var.enable_versioning
}
