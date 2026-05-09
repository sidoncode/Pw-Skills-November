
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

# -----------------------------
# Vault Provider
# -----------------------------

provider "vault" {
  address = "http://127.0.0.1:8200"
}

# -----------------------------
# Read AWS Secrets from Vault
# -----------------------------
data "vault_kv_secret_v2" "aws" {
  mount = "secret"
  name  = "aws"
}

# -----------------------------
# AWS Provider
# -----------------------------
provider "aws" {
  region     = "ap-south-1"

  access_key = data.vault_kv_secret_v2.aws.data["access_key"]
  secret_key = data.vault_kv_secret_v2.aws.data["secret_key"]
}

# -----------------------------
# EC2 Instance
# -----------------------------
resource "aws_instance" "demo" {
  ami           = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"

  tags = {
    Name = "TerraformVaultEC2"
  }
}

# Output

output "instance_public_ip" {
  value = aws_instance.demo.public_ip
}
