resource "aws_lb" "backend_alb" {
  name = "backend-alb"
  #   internal = false # default
  #   load_balancer_type = "application"

  subnets         = [aws_subnet.public.id, aws_subnet.public-2.id]
  security_groups = [aws_security_group.allow_all_sg.id]

  tags = {
    Name = "backend-alb"
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-tg"
  vpc_id   = aws_vpc.main.id
  port     = 5173
  protocol = "HTTP"
}

resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = 5173
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}


