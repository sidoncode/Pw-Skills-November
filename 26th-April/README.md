# Terraform Complete HCL Tutorial

[![Terraform](https://img.shields.io/badge/terraform-%3E%3D%201.0-blue.svg)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/aws%20provider-%7E%205.0-orange.svg)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive guide to learning Terraform Infrastructure as Code with properly formatted HCL examples ready for production use.

## 📚 Contents

- **TERRAFORM_COMPLETE_GUIDE.md** - Full tutorial covering all concepts
- **EXAMPLES.md** - Real-world HCL examples with complete code
- **QUICK_REFERENCE.md** - Commands and syntax cheat sheet (coming soon)
- **Organized code examples** for VSCode and production

## 🎯 What You'll Learn

### Fundamentals
- ✅ Terraform installation and setup
- ✅ Provider configuration
- ✅ Creating resources
- ✅ State management basics

### Intermediate
- ✅ Input variables and validation
- ✅ Output values
- ✅ Local values
- ✅ Data sources

### Advanced
- ✅ Module creation and composition
- ✅ Workspaces and multi-environment setup
- ✅ Conditional resources
- ✅ Dynamic blocks
- ✅ For expressions and splat syntax
- ✅ Complex data transformations

### Best Practices
- ✅ File organization
- ✅ Naming conventions
- ✅ Security considerations
- ✅ State management
- ✅ Testing and validation
- ✅ Version control integration

## 📖 Quick Start

### 1. Install Terraform

```bash
# macOS
brew install terraform

# Windows
choco install terraform

# Verify
terraform --version
```

### 2. Configure AWS Credentials

```bash
aws configure
# Or set environment variables:
# export AWS_ACCESS_KEY_ID=your_key
# export AWS_SECRET_ACCESS_KEY=your_secret
```

### 3. Create Your First Configuration

```bash
# Create directory
mkdir my-terraform-project
cd my-terraform-project

# Create provider.tf
cat > provider.tf << 'EOF'
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
}
EOF

# Create main.tf
cat > main.tf << 'EOF'
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket-${data.aws_caller_identity.current.account_id}"
  tags = {
    Name = "My Bucket"
  }
}

data "aws_caller_identity" "current" {}
EOF

# Create variables.tf
cat > variables.tf << 'EOF'
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
EOF

# Create outputs.tf
cat > outputs.tf << 'EOF'
output "bucket_name" {
  value = aws_s3_bucket.example.id
}
EOF
```

### 4. Run Terraform

```bash
# Initialize
terraform init

# Preview changes
terraform plan

# Apply configuration
terraform apply

# View outputs
terraform output

# Cleanup
terraform destroy
```

## 📂 File Organization

```
terraform-project/
├── README.md                    # Project documentation
├── provider.tf                  # Provider and version configs
├── main.tf                      # Resource definitions
├── variables.tf                 # Variable declarations
├── outputs.tf                   # Output values
├── terraform.tfvars             # Variable values
├── .gitignore                   # Git ignore rules
└── modules/                     # Reusable modules
    └── vpc/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🔑 Key Concepts

### Variables

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small"], var.instance_type)
    error_message = "Invalid instance type."
  }
}
```

### Resources

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"

  tags = {
    Name = "My Bucket"
  }
}
```

### Outputs

```hcl
output "bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.example.id
  sensitive   = false
}
```

### Modules

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  cidr_block = "10.0.0.0/16"
  environment = "prod"
}
```

## 💡 Common Commands

### Planning & Applying

```bash
# Show what will change
terraform plan

# Apply changes
terraform apply

# Auto-approve (use with caution)
terraform apply -auto-approve

# Target specific resource
terraform apply -target=aws_s3_bucket.example

# Use variable file
terraform apply -var-file="prod.tfvars"
```

### State Management

```bash
# Show current state
terraform show

# List resources
terraform state list

# Show specific resource
terraform state show aws_s3_bucket.example

# Remove from state
terraform state rm aws_s3_bucket.example
```

### Validation & Formatting

```bash
# Validate syntax
terraform validate

# Format code
terraform fmt -recursive

# Check format without changing
terraform fmt -check
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
```

## 📋 Common Patterns

### Conditional Resources

```hcl
# Only create in production
resource "aws_backup_vault" "example" {
  count = var.environment == "prod" ? 1 : 0
  name  = "backup-vault"
}
```

### Looping with for_each

```hcl
resource "aws_security_group_rule" "example" {
  for_each = var.security_rules

  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = aws_security_group.example.id
}
```

### Dynamic Blocks

```hcl
resource "aws_security_group" "example" {
  name = "example"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
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

## 🔒 Security Best Practices

### 1. Never Hardcode Secrets

```hcl
# ❌ DON'T
variable "db_password" {
  default = "MyPassword123!"
}

# ✅ DO
variable "db_password" {
  type      = string
  sensitive = true
  # Pass via: terraform apply -var="db_password=..."
}
```

### 2. Use Remote State

```hcl
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

### 3. Validate Inputs

```hcl
variable "port" {
  type = number

  validation {
    condition     = var.port > 0 && var.port < 65535
    error_message = "Port must be between 1 and 65534."
  }
}
```

### 4. Protect Sensitive Outputs

```hcl
output "db_password" {
  value     = aws_db_instance.example.password
  sensitive = true
}
```

## 📚 Documentation Structure

1. **TERRAFORM_COMPLETE_GUIDE.md**
   - Installation guide
   - Basic setup tutorial
   - Variables, outputs, modules
   - Workspaces
   - Advanced examples
   - Best practices
   - Commands reference

2. **EXAMPLES.md**
   - Basic S3 bucket
   - EC2 with VPC
   - RDS database
   - Load balancer
   - All production-ready code

3. **Code Examples**
   - All formatted for VSCode
   - Copy-paste ready
   - No word wrapping
   - Proper indentation

## 🧪 Testing & Validation

### Validate Syntax

```bash
terraform validate
```

### Format Code

```bash
terraform fmt -recursive
```

### Check for Issues

```bash
# Install tflint
brew install tflint

# Run linter
tflint

# Install Checkov for security
pip install checkov

# Check for security issues
checkov -d .
```

## 🚀 Deployment Workflow

```bash
# 1. Clone or fork the repository
git clone https://github.com/yourusername/terraform-tutorial.git
cd terraform-tutorial

# 2. Create your configuration
mkdir -p my-project
cd my-project

# 3. Initialize
terraform init

# 4. Plan changes
terraform plan -out=tfplan

# 5. Review plan
cat tfplan

# 6. Apply
terraform apply tfplan

# 7. Verify
terraform output

# 8. Cleanup
terraform destroy
```

## 📖 Learning Resources

- [Official Terraform Docs](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Registry](https://registry.terraform.io) - Modules and providers
- [HashiCorp Learn](https://learn.hashicorp.com) - Interactive tutorials
- [Terraform Best Practices](https://www.terraform-best-practices.com)

## ❓ Troubleshooting

### Backend initialization required
```bash
terraform init
```

### Resource already exists
```bash
terraform import aws_s3_bucket.example my-bucket
```

### State is locked
```bash
terraform force-unlock LOCK_ID
```

### Validation error
```bash
terraform validate
```

### Format issues
```bash
terraform fmt -recursive
```

## 📋 Checklist Before Production

- [ ] All variables have descriptions
- [ ] Sensitive data is marked with `sensitive = true`
- [ ] Output values are documented
- [ ] Code is formatted with `terraform fmt`
- [ ] Configuration validated with `terraform validate`
- [ ] Plan reviewed with `terraform plan`
- [ ] Remote state backend configured
- [ ] State locking enabled with DynamoDB
- [ ] Encryption enabled for state
- [ ] IAM permissions restricted
- [ ] Git ignore configured properly
- [ ] Version control initialized
- [ ] README.md created for documentation

## 🔗 Related Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Terraform Modules](https://registry.terraform.io/browse/modules)
- [Terraform Community](https://discuss.hashicorp.com/c/terraform/27)

## 📝 License

This tutorial is provided under the MIT License - see LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📧 Support

For questions or issues:
1. Check the [FAQ](#faq) section
2. Review [TERRAFORM_COMPLETE_GUIDE.md](./TERRAFORM_COMPLETE_GUIDE.md)
3. Check [EXAMPLES.md](./EXAMPLES.md)
4. Open an issue on GitHub

## 🎓 Next Steps After Learning

1. Create your own Terraform project
2. Deploy real infrastructure
3. Set up CI/CD integration
4. Explore Terraform Cloud
5. Learn about policy as code
6. Master advanced patterns

---

**Start Learning:** Begin with [TERRAFORM_COMPLETE_GUIDE.md](./TERRAFORM_COMPLETE_GUIDE.md)

**See Examples:** Check [EXAMPLES.md](./EXAMPLES.md)

**Happy Terraforming! 🚀**
