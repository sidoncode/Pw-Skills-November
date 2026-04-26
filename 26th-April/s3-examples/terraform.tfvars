# Terraform Variables Values
# File: terraform.tfvars

aws_region        = "us-east-1"
environment       = "dev"
project_name      = "myapp"
enable_versioning = true

tags = {
  ManagedBy   = "Terraform"
  Project     = "MyApp"
  Environment = "dev"
  Owner       = "DevOps"
}
