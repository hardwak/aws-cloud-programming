#ec2 instances
resource "aws_instance" "public_ec2_frontend" {
  ami                         = "ami-0014a768bde80541f" #ami with preinstalled docker
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  associate_public_ip_address = true
  key_name                    = "aws-app-key"

  user_data = <<-EOF
    #!/bin/bash
    
    sudo systemctl enable docker
    sudo systemctl start docker
    
    cat > /home/ec2-user/.env << EOL
    PUBLIC_API_BASE_URL=http://${aws_lb.backend_alb.dns_name}:8080
    EOL
    
    docker pull hardwak/cloud-frontend-nohost:latest
    docker run -d -p 5173:5173 --env-file /home/ec2-user/.env hardwak/cloud-frontend-nohost:latest
  EOF

  user_data_replace_on_change = true

  tags = {
    Name = "public_ec2_frontend"
  }
}

resource "aws_instance" "private_ec2_backend" {
  ami                         = "ami-0014a768bde80541f"
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.private.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  key_name                    = "aws-app-key"

  user_data = <<-EOF
    #!/bin/bash
    
    sudo systemctl enable docker
    sudo systemctl start docker

    cat > /home/ec2-user/.env << EOL
    CORS_ALLOWED_ORIGINS=http://${aws_instance.public_ec2_frontend.public_ip}:5173
    EOL
    
    docker pull hardwak/cloud-backend:latest
    docker run -d -p 8080:8081 --env-file /home/ec2-user/.env hardwak/cloud-backend:latest
  EOF

  user_data_replace_on_change = true

  tags = {
    Name = "private_ec2_backend"
  }
}
