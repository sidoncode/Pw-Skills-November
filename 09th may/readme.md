# Terraform Vault Integration Guide

A comprehensive guide to integrating **HashiCorp Vault** with **Terraform** for secure credential management and infrastructure provisioning on AWS.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Tutorials](#tutorials)
  - [Basic Vault Secret Retrieval](#tutorial-1-basic-vault-secret-retrieval)
  - [AWS EC2 Instance with Vault](#tutorial-2-aws-ec2-instance-with-vault)
  - [S3 Bucket with Vault and Modules](#tutorial-3-s3-bucket-with-vault-and-terraform-modules)
- [Configuration](#configuration)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Overview

This repository demonstrates how to use **HashiCorp Vault** as a centralized secrets management solution with **Terraform** for:

- **Secure credential storage** - Store AWS credentials in Vault
- **Secret retrieval** - Fetch secrets dynamically in Terraform
- **Infrastructure as Code** - Provision AWS resources using Terraform
- **Modular deployments** - Use Terraform modules for reusable infrastructure

### Key Benefits

✅ **Centralized Secrets Management** - No hardcoded credentials in code  
✅ **Audit Trail** - Track who accessed what secrets and when  
✅ **Dynamic Credentials** - Rotate credentials without updating code  
✅ **Infrastructure Automation** - Provision resources with secure credentials  
✅ **Modular Architecture** - Reuse Terraform modules across projects

---

## 📦 Prerequisites

Before getting started, ensure you have the following installed:

- **Terraform** (v1.0+)
  - [Download](https://www.terraform.io/downloads.html)
  
- **Vault** (v1.12+)
  - [Download](https://www.vaultproject.io/downloads)
  
- **AWS CLI** (v2+)
  - [Download](https://aws.amazon.com/cli/)
  
- **Git**
  - [Download](https://git-scm.com/)

### AWS Account Requirements

- Valid AWS Account with appropriate IAM permissions
- AWS Access Key ID and Secret Access Key

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/terraform-vault-integration.git
cd terraform-vault-integration
```

### 2. Start Vault in Development Mode

```bash
vault server -dev
```

This will start a development Vault server at `http://127.0.0.1:8200`

**Note:** Copy the `Unseal Key` and `Root Token` displayed in the output.

### 3. Set Environment Variables

#### On macOS/Linux

```bash
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="hvs.xxxxxx"  # Replace with your Root Token
```

#### On Windows (PowerShell)

```powershell
$env:VAULT_ADDR="http://127.0.0.1:8200"
$env:VAULT_TOKEN="hvs.xxxxxx"  # Replace with your Root Token
```

### 4. Store AWS Credentials in Vault

```bash
vault kv put secret/aws \
  access_key=AKIA_YOUR_ACCESS_KEY \
  secret_key=YOUR_SECRET_KEY
```

### 5. Verify Secrets

```bash
vault kv get secret/aws
```

---

## 📁 Project Structure

```
terraform-vault-integration/
├── README.md
├── tutorial-1-basic-vault/
│   ├── main.tf
│   └── outputs.tf
├── tutorial-2-ec2-vault/
│   ├── main.tf
│   └── outputs.tf
├── tutorial-3-s3-vault-modules/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── .gitignore
└── docs/
    ├── vault-setup.md
    ├── aws-setup.md
    └── troubleshooting.md
```

---

## 🎓 Tutorials

### Tutorial 1: Basic Vault Secret Retrieval

Learn how to retrieve database credentials from Vault using Terraform.

#### Step 1 — Create Project Directory

```bash
mkdir terraform-vault-demo
cd terraform-vault-demo
touch main.tf
```

#### Step 2 — Add Terraform Configuration

Create `main.tf` with the following content:

```hcl
terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

provider "vault" {
  address = "http://127.0.0.1:8200"
}

data "vault_kv_secret_v2" "db" {
  mount = "secret"
  name  = "db"
}

output "db_username" {
  value = data.vault_kv_secret_v2.db.data["username"]
}

output "db_password" {
  value     = data.vault_kv_secret_v2.db.data["password"]
  sensitive = true
}
```

#### Step 3 — Initialize Terraform

```bash
terraform init
```

Terraform will download the Vault provider.

#### Step 4 — Plan and Apply

```bash
terraform plan
terraform apply -auto-approve
```

You will see the outputs:
```
db_username = myuser
db_password = <sensitive>
```

---

### Tutorial 2: AWS EC2 Instance with Vault

Provision an EC2 instance using AWS credentials stored in Vault.

#### Step 1 — Create Project Directory

```bash
mkdir terraform-ec2-vault
cd terraform-ec2-vault
touch main.tf
```

#### Step 2 — Store AWS Credentials in Vault

```bash
vault kv put secret/aws \
  access_key=AKIA_YOUR_ACCESS_KEY \
  secret_key=YOUR_SECRET_KEY
```

#### Step 3 — Verify Credentials

```bash
vault kv get secret/aws
```

#### Step 4 — Add Terraform Configuration

Create `main.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

# Vault Provider
provider "vault" {
  address = "http://127.0.0.1:8200"
}

# Read AWS Secrets from Vault
data "vault_kv_secret_v2" "aws" {
  mount = "secret"
  name  = "aws"
}

# AWS Provider
provider "aws" {
  region     = "ap-south-1"
  access_key = data.vault_kv_secret_v2.aws.data["access_key"]
  secret_key = data.vault_kv_secret_v2.aws.data["secret_key"]
}

# EC2 Instance
resource "aws_instance" "demo" {
  ami           = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"
  
  tags = {
    Name = "TerraformVaultEC2"
  }
}

# Output
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.demo.public_ip
}
```

#### Step 5 — Initialize Terraform

```bash
terraform init
```

#### Step 6 — Validate Configuration

```bash
terraform validate
```

#### Step 7 — Plan Deployment

```bash
terraform plan
```

#### Step 8 — Create EC2 Instance

```bash
terraform apply -auto-approve
```

**Output:**
```
instance_public_ip = xx.xx.xx.xx
```

#### Step 9 — Verify in AWS Console

1. Navigate to [AWS Console](https://console.aws.amazon.com/)
2. Go to **EC2 → Instances**
3. Look for instance named **TerraformVaultEC2**

#### Step 10 — Cleanup

To avoid AWS charges:

```bash
terraform destroy -auto-approve
```

---

### Tutorial 3: S3 Bucket with Vault and Terraform Modules

Create an S3 bucket using Terraform modules and AWS credentials from Vault.

#### Step 1 — Create Project Directory

```bash
mkdir terraform-s3-vault-modules
cd terraform-s3-vault-modules
touch main.tf variables.tf outputs.tf
```

#### Step 2 — Store AWS Credentials in Vault

```bash
vault kv put secret/aws \
  access_key=AKIA_YOUR_ACCESS_KEY \
  secret_key=YOUR_SECRET_KEY
```

#### Step 3 — Add Terraform Configuration

Create `main.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.42.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

# Vault Provider
provider "vault" {
  address = "http://127.0.0.1:8200"
}

# Read AWS Credentials from Vault
data "vault_kv_secret_v2" "aws" {
  mount = "secret"
  name  = "aws"
}

# AWS Provider
provider "aws" {
  region     = var.aws_region
  access_key = data.vault_kv_secret_v2.aws.data["access_key"]
  secret_key = data.vault_kv_secret_v2.aws.data["secret_key"]
}

# S3 Bucket Module
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  
  bucket = var.bucket_name
  acl    = "private"
  
  control_object_ownership = true
  object_ownership         = "ObjectWriter"
  
  versioning = {
    enabled = true
  }
  
  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

Create `variables.tf`:

```hcl
variable "aws_region" {
  description = "AWS region for S3 bucket"
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
  default     = "my-terraform-vault-bucket-12345"
}
```

Create `outputs.tf`:

```hcl
output "bucket_id" {
  description = "The name of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_arn
}

output "bucket_region" {
  description = "The AWS region of the S3 bucket"
  value       = var.aws_region
}
```

#### Step 4 — Initialize Terraform

```bash
terraform init
```

#### Step 5 — Plan Deployment

```bash
terraform plan
```

#### Step 6 — Create S3 Bucket

```bash
terraform apply -auto-approve
```

**Output:**
```
bucket_id  = my-terraform-vault-bucket-12345
bucket_arn = arn:aws:s3:::my-terraform-vault-bucket-12345
bucket_region = ap-south-1
```

#### Step 7 — Verify in AWS Console

1. Navigate to [S3 Console](https://s3.console.aws.amazon.com/)
2. Look for your bucket in the list
3. Verify versioning is enabled

#### Step 8 — Cleanup

```bash
terraform destroy -auto-approve
```

---

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `VAULT_ADDR` | Vault server address | `http://127.0.0.1:8200` |
| `VAULT_TOKEN` | Vault authentication token | `hvs.xxxxx` |
| `AWS_REGION` | AWS region | `ap-south-1` |

### Terraform Variables

Customize deployments using `terraform.tfvars`:

```hcl
aws_region  = "ap-south-1"
bucket_name = "my-unique-bucket-name"
```

---

## 🧹 Cleanup

### Destroy All Resources

To prevent unexpected AWS charges, always clean up resources:

```bash
terraform destroy -auto-approve
```

### Stop Vault Server

Press `Ctrl + C` in the terminal running the Vault server.

---

## 🆘 Troubleshooting

### Issue: "Failed to read secret from Vault"

**Solution:**
- Verify Vault is running: `vault status`
- Check `VAULT_TOKEN` is set correctly
- Ensure the secret path exists: `vault kv list secret/`

### Issue: "Error: error configuring Terraform AWS Provider"

**Solution:**
- Verify AWS credentials in Vault: `vault kv get secret/aws`
- Check IAM user has required permissions
- Ensure credentials haven't expired

### Issue: "Error: failed to query available provider packages"

**Solution:**
- Clear Terraform cache: `rm -rf .terraform`
- Run `terraform init` again

### Issue: "S3 bucket name already exists"

**Solution:**
- S3 bucket names are globally unique
- Change `bucket_name` variable to a unique name
- Bucket names must be 3-63 characters, lowercase, and numbers/hyphens only

---

## 📚 Additional Resources

- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Vault Provider](https://registry.terraform.io/providers/hashicorp/vault/latest/docs)
- [AWS Terraform Modules](https://github.com/terraform-aws-modules)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices)

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## ⚠️ Security Notes

🔒 **Never commit sensitive information to version control:**
- Never commit Vault tokens or AWS credentials
- Use `.gitignore` to exclude:
  - `*.tfvars` (if containing secrets)
  - `.terraform/` directory
  - `terraform.tfstate` and `terraform.tfstate.backup`
  - `.env` files

**Example `.gitignore`:**
```
# Terraform
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl

# Environment variables
.env
terraform.tfvars

# IDE
.idea/
.vscode/
*.swp
*.swo
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📧 Support

For issues, questions, or suggestions:
- Open an [GitHub Issue](https://github.com/yourusername/terraform-vault-integration/issues)
- Contact the maintainers

---

**Happy Infrastructure Coding! 🚀**

Last Updated: 2026
