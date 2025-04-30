resource "aws_lb" "app_alb" {
  name = "app-alb"
  #   internal = false # default
  #   load_balancer_type = "application"

  subnets         = [aws_subnet.public.id, aws_subnet.public-2.id]
  security_groups = [aws_security_group.alb_sg.id]

  tags = {
    Name = "app-alb"
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "backend-tg"
  vpc_id      = aws_vpc.main.id
  port        = 8081
  protocol    = "HTTP"
  target_type = "ip"
}

resource "aws_lb_target_group" "frontend_tg" {
  name        = "frontend-tg"
  vpc_id      = aws_vpc.main.id
  port        = 5173
  protocol    = "HTTP"
  target_type = "ip"
}

resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 8081
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 5173
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}


