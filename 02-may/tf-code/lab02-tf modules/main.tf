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
