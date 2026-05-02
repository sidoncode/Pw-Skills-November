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
