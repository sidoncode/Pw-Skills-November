# terraform core

## user -> attach policy directly

1. AdministratorAccess
2. AmazonEC2FullAccess
3. AmazonS3FullAccess
4. AmazonVPCFullAccess

#main.tf

terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
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
  ami             = ami-091138d0f0d41ff90
  instance_type   = t3.micro
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
  
  
  ===== terraform modules ==
  
  my-terraform-project/
|-- main.tf             <- Calls the module
|-- variables.tf        <- Project variables
|-- outputs.tf          <- Project outputs
|-- terraform.tfvars    <- Variable values
|
\-- modules/
    \-- vpc/
        |-- main.tf     <- Module: creates the VPC resources
        |-- variables.tf <- Module: its own input variables
        \-- outputs.tf  <- Module: what it returns to the caller


>> == module == vpc

for an example: ec2 - port 22(ssh) : enable
{
ec2 - module : main.tf , variables.tf and output.tf
}

Custom module - create once - reUse everyWhere.

import /ec2 - module

tf - variables

====

File 1 of 3: modules/vpc/main.tf

# modules/vpc/main.tf
# This module creates a VPC and a subnet
 
resource "aws_vpc" "this" {
  # var.vpc_cidr comes from the module's variables.tf
  cidr_block = var.vpc_cidr
 
  tags = {
    Name = var.vpc_name
  }
}
 
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.subnet_cidr
 
  tags = {
    Name = "${var.vpc_name}-public-subnet"
  }
}

====

File 2 of 3: modules/vpc/variables.tf

# modules/vpc/variables.tf
# These are the INPUTS the module accepts
 
variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
}
 
variable "vpc_cidr" {
  description = "IP range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
 
variable "subnet_cidr" {
  description = "IP range for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

====

File 3 of 3: modules/vpc/outputs.tf

# modules/vpc/outputs.tf
# These are the OUTPUTS the module returns to the caller
 
output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.this.id
}
 
output "subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public.id
}


=== ROOT directory - main.tf ===

# main.tf (root level - the file that uses the module)
 
provider "aws" {
  region = "us-east-1"
}
 
# ---- Call our VPC module ----
module "my_vpc" {
  # source = path to the module folder
  source = "./modules/vpc"
 
  # Pass values into the module's input variables
  vpc_name    = "production-vpc"
  vpc_cidr    = "10.0.0.0/16"
  subnet_cidr = "10.0.1.0/24"
}
 


=========

>> terraform init
>> terraform validate
>> terraform fmt
>> terraform plan
>> terraform apply
  
  
  
  
  
}

