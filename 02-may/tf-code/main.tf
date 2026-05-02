terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

# region
provider "aws" {
  region = "us-east-1"
}

# nginx : install
# nginx : SG -> inbound / outbound
# nginx : inbound: 80, 22 -> ingress
# nginx : outbound: all -> egress

resource "aws_security_group" "nginx_sg" {
  name        = "nginx-sg"
  description = "Security group for nginx server"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# ── EC2 Instance ──────────────────────────────────────────────────
resource "aws_instance" "nginx_server" {
  ami             = "ami-091138d0f0d41ff90"
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.nginx_sg.name]

  user_data = <<-SCRIPT
    #!/bin/bash
    sudo apt update
    sudo apt install nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Hello from Terraform + Nginx!</h1>" \
      > /usr/share/nginx/html/index.html
  SCRIPT

  tags = { Name = "nginx-ec2-server" }
}

