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
