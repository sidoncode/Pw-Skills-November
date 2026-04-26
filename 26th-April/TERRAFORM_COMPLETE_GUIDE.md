# Terraform Complete HCL Tutorial

A comprehensive guide to learning Terraform Infrastructure as Code with properly formatted HCL examples ready for VSCode and production use.

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Basic Setup](#basic-setup)
4. [Variables](#variables)
5. [Outputs](#outputs)
6. [Modules](#modules)
7. [Workspaces](#workspaces)
8. [Advanced Examples](#advanced-examples)
9. [Best Practices](#best-practices)
10. [Commands Reference](#commands-reference)

---

## Introduction

Terraform is an Infrastructure as Code tool that allows you to define, preview, and deploy infrastructure using declarative configuration files written in HCL (HashiCorp Configuration Language).

### Key Concepts

- **Provider**: Cloud service (AWS, Azure, GCP)
- **Resources**: Infrastructure objects (EC2, S3, RDS)
- **Variables**: Input parameters
- **Outputs**: Values to display after apply
- **Modules**: Reusable configuration packages
- **State**: Tracking of deployed resources

---

## Installation

### macOS (Homebrew)

```bash
brew install terraform
terraform --version
```

### Windows (Chocolatey)

```bash
choco install terraform
terraform --version
```

### Linux

```bash
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version
```

### Configure AWS Credentials

```bash
aws configure
# Or create ~/.aws/credentials file:
# [default]
# aws_access_key_id = YOUR_ACCESS_KEY
# aws_secret_access_key = YOUR_SECRET_KEY
```

---

## Basic Setup

### Project Directory Structure

```
my-terraform-project/
├── provider.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── .gitignore
```

### provider.tf - Configure Terraform and AWS

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Terraform = "true"
      Project   = "MyProject"
      ManagedBy = "Terraform"
    }
  }
}
```

### main.tf - Define Resources

```hcl
# Create S3 bucket
resource "aws_s3_bucket" "example" {
  bucket = "my-unique-bucket-name-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "My Bucket"
    Environment = "dev"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
```

### variables.tf - Define Input Variables

```hcl
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "bucket_name" {
  description = "Name of S3 bucket"
  type        = string
}

variable "enable_versioning" {
  description = "Enable bucket versioning"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
```

### outputs.tf - Display Values

```hcl
output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.example.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.example.arn
}

output "bucket_region" {
  description = "The region of the S3 bucket"
  value       = aws_s3_bucket.example.region
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.example.bucket_regional_domain_name
}

output "versioning_enabled" {
  description = "Whether versioning is enabled"
  value       = aws_s3_bucket_versioning.example.versioning_configuration[0].status
}
```

### terraform.tfvars - Provide Variable Values

```hcl
aws_region       = "us-east-1"
environment      = "dev"
bucket_name      = "my-app-bucket-dev"
enable_versioning = true

tags = {
  ManagedBy   = "Terraform"
  Project     = "MyApp"
  Environment = "dev"
  Owner       = "DevOps"
}
```

### .gitignore - Ignore Sensitive Files

```
# Terraform state
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl

# Variable files
*.tfvars
*.tfvars.json

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
```

---

## Variables

### Variable Types

#### String Variables

```hcl
variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}
```

#### Number Variables

```hcl
variable "instance_count" {
  type        = number
  description = "Number of instances"
  default     = 2

  validation {
    condition     = var.instance_count > 0
    error_message = "Count must be greater than 0."
  }
}
```

#### Boolean Variables

```hcl
variable "enable_monitoring" {
  type        = bool
  description = "Enable CloudWatch monitoring"
  default     = true
}
```

#### List Variables

```hcl
variable "availability_zones" {
  type        = list(string)
  description = "List of AZs"
  default     = ["us-east-1a", "us-east-1b"]
}
```

#### Map Variables

```hcl
variable "tags" {
  type        = map(string)
  description = "Tags to apply"
  default = {
    Environment = "dev"
    Project     = "MyApp"
  }
}
```

#### Object Variables

```hcl
variable "database_config" {
  type = object({
    engine         = string
    instance_class = string
    allocated_storage = number
  })

  default = {
    engine             = "postgres"
    instance_class     = "db.t3.micro"
    allocated_storage  = 20
  }
}
```

### Using Variables

```hcl
# Reference in resources
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = var.instance_type
  count         = var.instance_count

  tags = var.tags
}

# Use in locals
locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
    }
  )
}
```

### Variable Precedence (Highest to Lowest)

1. `-var` command line flags
2. `-var-file` argument
3. `*.auto.tfvars` files (alphabetical order)
4. `terraform.tfvars` file
5. Environment variables (`TF_VAR_name`)
6. Default values in variable definition

### Providing Variable Values

```bash
# Via command line
terraform apply -var="instance_type=t3.medium"

# Via file
terraform apply -var-file="prod.tfvars"

# Via environment variable
export TF_VAR_instance_type=t3.medium
terraform apply

# Automatically loaded
# - terraform.tfvars
# - *.auto.tfvars
```

---

## Outputs

### Output Syntax

```hcl
output "instance_id" {
  description = "The ID of the instance"
  value       = aws_instance.example.id
  sensitive   = false
}

output "database_password" {
  description = "Database password"
  value       = aws_db_instance.example.password
  sensitive   = true  # Value won't be shown in logs
}
```

### Display Outputs

```bash
# Show all outputs
terraform output

# Get specific output
terraform output instance_id

# Output in JSON
terraform output -json
```

### Complex Outputs

```hcl
output "instance_details" {
  description = "Details of all instances"
  value = {
    ids          = aws_instance.example[*].id
    private_ips  = aws_instance.example[*].private_ip
    public_ips   = aws_instance.example[*].public_ip
  }
}

output "instance_map" {
  description = "Map of instances"
  value = {
    for instance in aws_instance.example :
    instance.tags["Name"] => instance.id
  }
}
```

---

## Modules

### Module Directory Structure

```
project/
├── modules/
│   └── vpc/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── main.tf
└── variables.tf
```

### Create a Module

#### modules/vpc/variables.tf

```hcl
variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}
```

#### modules/vpc/main.tf

```hcl
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-vpc"
    }
  )
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-public-subnet"
    }
  )
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-private-subnet"
    }
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-igw"
    }
  )
}

data "aws_availability_zones" "available" {
  state = "available"
}
```

#### modules/vpc/outputs.tf

```hcl
output "vpc_id" {
  description = "The VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "The VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_id" {
  description = "The public subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "The private subnet ID"
  value       = aws_subnet.private.id
}

output "internet_gateway_id" {
  description = "The internet gateway ID"
  value       = aws_internet_gateway.this.id
}
```

### Use Modules

```hcl
# Call the VPC module
module "vpc" {
  source = "./modules/vpc"

  cidr_block = "10.0.0.0/16"
  environment = var.environment

  tags = {
    Project = "MyApp"
    Owner   = "DevOps"
  }
}

# Use module outputs
resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnet_id

  tags = {
    Name = "app-server"
  }
}
```

### Multiple Module Instances

```hcl
# Create multiple environments
module "vpc_dev" {
  source      = "./modules/vpc"
  cidr_block  = "10.0.0.0/16"
  environment = "dev"
}

module "vpc_prod" {
  source      = "./modules/vpc"
  cidr_block  = "10.1.0.0/16"
  environment = "prod"
}

# Or use for_each
module "vpc" {
  for_each = {
    dev     = "10.0.0.0/16"
    staging = "10.1.0.0/16"
    prod    = "10.2.0.0/16"
  }

  source      = "./modules/vpc"
  cidr_block  = each.value
  environment = each.key
}
```

---

## Workspaces

### Workspace Commands

```bash
# List workspaces
terraform workspace list

# Create workspace
terraform workspace new production

# Switch workspace
terraform workspace select production

# Show current workspace
terraform workspace show

# Delete workspace
terraform workspace delete staging
```

### Use Workspaces in Configuration

```hcl
locals {
  environment_config = {
    dev = {
      instance_type = "t3.micro"
      instance_count = 1
    }
    prod = {
      instance_type = "t3.large"
      instance_count = 3
    }
  }

  current_env = terraform.workspace
  env_config  = local.environment_config[local.current_env]
}

resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = local.env_config.instance_type
  count         = local.env_config.instance_count

  tags = {
    Name        = "${local.current_env}-app-${count.index + 1}"
    Environment = local.current_env
  }
}
```

### Workspace-Specific Variables

Create separate `.tfvars` files for each workspace:

```bash
dev.tfvars
prod.tfvars
staging.tfvars
```

Use them with workspaces:

```bash
terraform workspace select dev
terraform apply -var-file="dev.tfvars"

terraform workspace select prod
terraform apply -var-file="prod.tfvars"
```

---

## Advanced Examples

### Conditional Resources

```hcl
resource "aws_s3_bucket_versioning" "example" {
  # Only create if versioning is enabled
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.example.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

### Looping with for_each

```hcl
variable "security_group_rules" {
  type = map(object({
    from_port = number
    to_port   = number
    protocol  = string
  }))

  default = {
    http = {
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
    }
    https = {
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
    }
  }
}

resource "aws_security_group_rule" "app" {
  for_each = var.security_group_rules

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.example.id
}
```

### Dynamic Blocks

```hcl
variable "ingress_rules" {
  type = list(object({
    from_port = number
    to_port   = number
    protocol  = string
    cidr_blocks = list(string)
  }))
}

resource "aws_security_group" "example" {
  name        = "example"
  description = "Example security group"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### Local Values

```hcl
locals {
  # Derive values from variables
  bucket_prefix = "${var.environment}-${var.project_name}"

  # Combine multiple values
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }

  # Conditional values
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"

  # Map transformation
  instance_names = {
    for instance in aws_instance.app :
    instance.id => instance.tags["Name"]
  }
}

resource "aws_s3_bucket" "app" {
  bucket = "${local.bucket_prefix}-data"
  tags   = local.common_tags
}
```

### Splat Expressions

```hcl
# Get all instance IDs
output "instance_ids" {
  value = aws_instance.app[*].id
}

# Get all private IPs
output "private_ips" {
  value = aws_instance.app[*].private_ip
}

# Get specific attribute from list
output "instance_arns" {
  value = aws_instance.app[*].arn
}
```

### Data Sources

```hcl
# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Use data source in resource
resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}

# Get current AWS account
data "aws_caller_identity" "current" {}

# Use current account ID
resource "aws_s3_bucket" "logs" {
  bucket = "logs-${data.aws_caller_identity.current.account_id}"
}
```

### Functions

```hcl
# String functions
locals {
  uppercase_env = upper(var.environment)
  region_short  = substr(var.aws_region, 0, 2)
  is_prod       = startswith(var.environment, "prod")
  bucket_name   = join("-", ["my", var.project_name, var.environment])
}

# List functions
locals {
  all_subnets = concat(
    aws_subnet.public[*].id,
    aws_subnet.private[*].id
  )
  unique_azs = distinct(aws_subnet.public[*].availability_zone)
}

# Map functions
locals {
  env_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
  all_tags = merge(var.tags, local.env_tags)
}

# Type functions
locals {
  is_string = can(regex("^[a-z]+$", var.value))
  count_value = can(tonumber(var.value)) ? tonumber(var.value) : 0
}
```

---

## Best Practices

### 1. File Organization

```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── main.tf
│       ├── terraform.tfvars
│       └── backend.tf
├── modules/
│   ├── vpc/
│   ├── security/
│   └── compute/
└── shared/
    ├── outputs.tf
    └── variables.tf
```

### 2. State Management

```hcl
# Use remote backend for production
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### 3. Naming Conventions

```hcl
# Resource naming pattern: {environment}-{resource_type}-{function}
resource "aws_instance" "web_server" {
  tags = {
    Name = "${var.environment}-ec2-webserver"
  }
}

# Variable naming: lowercase with underscores
variable "instance_type" {
  type = string
}

# Local naming: clearly indicate scope
locals {
  common_tags = {
    Environment = var.environment
  }
}
```

### 4. Input Validation

```hcl
variable "instance_type" {
  type        = string
  description = "EC2 instance type"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Instance type must be t3.micro, t3.small, or t3.medium."
  }
}

variable "port" {
  type        = number
  description = "Port number"

  validation {
    condition     = var.port > 0 && var.port < 65535
    error_message = "Port must be between 1 and 65534."
  }
}
```

### 5. Documentation

```hcl
# Add descriptions to all variables and outputs
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

output "vpc_id" {
  description = "The VPC ID"
  value       = aws_vpc.main.id
}

# Add comments for complex logic
resource "aws_instance" "app" {
  # Use larger instances in production for better performance
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
}
```

### 6. Security

```hcl
# Never hardcode sensitive data
variable "db_password" {
  type        = string
  sensitive   = true
  description = "Database password"
  # Pass via: TF_VAR_db_password or -var-file
}

# Mark sensitive outputs
output "db_password" {
  value     = aws_db_instance.main.password
  sensitive = true
}

# Use data sources instead of hardcoding
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  # Query instead of hardcoding AMI ID
}
```

### 7. Testing and Validation

```bash
# Validate syntax
terraform validate

# Format code
terraform fmt -recursive

# Preview changes
terraform plan -out=tfplan

# Check for security issues
tflint
checkov -d .
```

### 8. Version Control

```bash
# Initialize Git
git init

# Create .gitignore
echo "*.tfstate*" > .gitignore
echo ".terraform/" >> .gitignore
echo "*.tfvars" >> .gitignore

# Commit files
git add *.tf
git commit -m "Initial Terraform configuration"
```

---

## Commands Reference

### Initialization and Configuration

```bash
# Initialize Terraform directory
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt
terraform fmt -recursive

# Download latest provider version
terraform init -upgrade
```

### Planning and Applying

```bash
# Show execution plan
terraform plan

# Save plan to file
terraform plan -out=tfplan

# Apply configuration
terraform apply

# Apply saved plan
terraform apply tfplan

# Apply without confirmation
terraform apply -auto-approve

# Apply with specific variables
terraform apply -var="environment=prod"

# Apply with variable file
terraform apply -var-file="prod.tfvars"
```

### State Management

```bash
# Show current state
terraform show

# List resources in state
terraform state list

# Show specific resource
terraform state show aws_s3_bucket.example

# Move resource
terraform state mv aws_s3_bucket.old aws_s3_bucket.new

# Remove resource from state
terraform state rm aws_s3_bucket.example

# View state in JSON
terraform state pull
```

### Workspaces

```bash
# List workspaces
terraform workspace list

# Create workspace
terraform workspace new production

# Switch workspace
terraform workspace select production

# Delete workspace
terraform workspace delete staging

# Show current workspace
terraform workspace show
```

### Debugging

```bash
# Enable debug logging
export TF_LOG=DEBUG

# Save logs to file
export TF_LOG_PATH=terraform.log

# Show resource graph
terraform graph

# Convert graph to SVG
terraform graph | dot -Tsvg > graph.svg

# Get specific output
terraform output vpc_id

# Get all outputs in JSON
terraform output -json
```

### Cleanup

```bash
# Plan destruction
terraform plan -destroy

# Destroy resources
terraform destroy

# Destroy without confirmation
terraform destroy -auto-approve

# Destroy specific resource
terraform destroy -target=aws_s3_bucket.example

# Destroy without confirmation for specific resource
terraform destroy -target=aws_s3_bucket.example -auto-approve
```

### Advanced

```bash
# Import existing resource
terraform import aws_s3_bucket.example my-bucket

# Force unlock state
terraform force-unlock LOCK_ID

# Refresh state
terraform refresh

# Taint resource (force replacement)
terraform taint aws_instance.example

# Untaint resource
terraform untaint aws_instance.example
```

---

## Common Patterns

### Multi-Environment Setup

```hcl
# environments/dev/terraform.tfvars
environment = "dev"
instance_type = "t3.micro"
instance_count = 1

# environments/prod/terraform.tfvars
environment = "prod"
instance_type = "t3.large"
instance_count = 3

# Workflow
# terraform workspace new dev
# terraform apply -var-file="environments/dev/terraform.tfvars"
# terraform workspace new prod
# terraform apply -var-file="environments/prod/terraform.tfvars"
```

### Reusable Module Composition

```hcl
# Root module calls multiple modules
module "vpc" {
  source = "./modules/vpc"
  cidr_block = var.vpc_cidr
}

module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id
}

module "compute" {
  source = "./modules/compute"
  subnet_id = module.vpc.public_subnet_id
  security_group_id = module.security.app_security_group_id
}
```

### Conditional Resource Creation

```hcl
# Create resource only in production
resource "aws_backup_vault" "example" {
  count = var.environment == "prod" ? 1 : 0
  name  = "backup-vault"
}

# Or use for larger conditions
locals {
  create_backup = var.environment == "prod" && var.enable_backups
}

resource "aws_backup_vault" "example" {
  count = local.create_backup ? 1 : 0
  name  = "backup-vault"
}
```

### Merge Tags

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_instance" "example" {
  tags = merge(
    local.common_tags,
    {
      Name = "my-instance"
    }
  )
}
```

---

## Troubleshooting

### Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| `Backend initialization required` | Run `terraform init` |
| `Resource already exists` | Use `terraform import` or change resource name |
| `State is locked` | Run `terraform force-unlock LOCK_ID` |
| `Variable validation failed` | Check variable values in tfvars file |
| `Module not found` | Ensure module path is correct, run `terraform get` |
| `Circular dependency` | Review resource dependencies, use explicit depends_on |
| `Invalid resource reference` | Check spelling of resource names and attributes |

### Debug Commands

```bash
# Enable maximum verbosity
export TF_LOG=TRACE
terraform apply

# Save detailed logs
export TF_LOG=DEBUG
export TF_LOG_PATH=/tmp/terraform.log
terraform apply

# View logs
cat /tmp/terraform.log
```

---

## Resources

- [Official Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Registry](https://registry.terraform.io)
- [HashiCorp Learn](https://learn.hashicorp.com)

---

## License

This tutorial is provided as-is for educational purposes.

---

**Happy Learning! 🚀 Start with the Basic Setup section and work your way through.**
