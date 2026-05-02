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
