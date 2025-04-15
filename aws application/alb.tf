resource "aws_lb" "backend_alb" {
  name = "backend-alb"
  #   internal = false # default
  #   load_balancer_type = "application"

  subnets         = [aws_subnet.public.id, aws_subnet.public-2.id]
  security_groups = [aws_security_group.alb_sg.id]

  tags = {
    Name = "backend-alb"
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-tg"
  vpc_id   = aws_vpc.main.id
  port     = 8080
  protocol = "HTTP"
}

resource "aws_lb_target_group_attachment" "backend_tg_attachment" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.private_ec2_backend.id
  port             = 8080
}

resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}


