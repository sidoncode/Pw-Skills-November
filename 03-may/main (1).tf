terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-terraform-state-2024"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# ── Security Group ────────────────────────────────────────────────
resource "aws_security_group" "nginx_sg" {
  name        = "nginx-sg"
  description = "Security group for nginx server"

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "nginx-sg" }
}

# ── EC2 Instance ──────────────────────────────────────────────────
resource "aws_instance" "nginx_server" {
  ami             = "ami-091138d0f0d41ff90"
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.nginx_sg.name]

  user_data = <<-SCRIPT
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Hello from Terraform + Nginx!</h1>" \
      > /var/www/html/index.html
  SCRIPT

  tags = { Name = "nginx-ec2-server" }
}
