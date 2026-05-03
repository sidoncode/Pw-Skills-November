output "instance_public_ip" {
  description = "Public IP of the nginx EC2 instance"
  value       = aws_instance.nginx_server.public_ip
}

output "nginx_url" {
  description = "Nginx URL"
  value       = "http://${aws_instance.nginx_server.public_ip}"
}
