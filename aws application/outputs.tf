output "public_ip" {
  value = aws_instance.public_ec2_frontend.public_ip
}

output "private_ip" {
  value = aws_instance.private_ec2_backend.private_ip
}

output "alb_dns_name" {
  value = aws_lb.backend_alb.dns_name
}
