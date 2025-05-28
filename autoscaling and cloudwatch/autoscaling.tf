resource "aws_launch_template" "instance_template" {
    name_prefix = "instance_template_"
    image_id = "ami-0014a768bde80541f"
    instance_type = "t3.micro"
    key_name = "aws-app-key"
    vpc_security_group_ids = [ aws_security_group.allow_all_sg.id ]
    user_data = base64encode(<<-EOF
    #!/bin/bash
    
    sudo systemctl enable docker
    sudo systemctl start docker
    
    cat > /home/ec2-user/.env << EOL
    PUBLIC_API_BASE_URL=http://localhost:8080
    EOL
    
    docker pull hardwak/cloud-frontend-nohost:latest
    docker run -d -p 5173:5173 --env-file /home/ec2-user/.env hardwak/cloud-frontend-nohost:latest
    EOF
    )

}

resource "aws_autoscaling_group" "asg" {
    vpc_zone_identifier = [aws_subnet.public.id, aws_subnet.public-2.id]
    min_size = 1
    max_size = 3
    desired_capacity = 2

    target_group_arns = [aws_lb_target_group.backend_tg.arn]

    tag {
        key = "Name"
        value = "My ASG"
        propagate_at_launch = true
    }

    launch_template {
        id = aws_launch_template.instance_template.id
        version = "$Latest"
    }
}

resource "aws_autoscaling_policy" "increase_instances" {
    name                   = "increase-instances"
    scaling_adjustment     = 1
    adjustment_type        = "ChangeInCapacity"
    cooldown               = 60
    autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "reduce_instances" {
    name                   = "reduce-instances"
    scaling_adjustment     = -1
    adjustment_type        = "ChangeInCapacity"
    cooldown               = 60
    autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_attachment" "asg_attachment" {
    autoscaling_group_name = aws_autoscaling_group.asg.id
    lb_target_group_arn = aws_lb_target_group.backend_tg.arn
}

resource "aws_sns_topic" "cpu_alarm_topic" {
  name = "cpu-alarm-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.cpu_alarm_topic.arn
  protocol  = "email"
  endpoint  = "276751@student.pwr.edu.pl"
}

resource "aws_cloudwatch_metric_alarm" "increase_ec2_count" {
  alarm_name                = "increase-ec2-count"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 70
  alarm_description         = "Alarm when ECS frontend service CPU exceeds 70% and increase instances number"

  alarm_actions = [
      aws_sns_topic.cpu_alarm_topic.arn,
      aws_autoscaling_policy.increase_instances.arn
  ]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "reduce_ec2_count" {
  alarm_name                = "reduce-ec2-count"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 40
  alarm_description         = "Alarm when ECS frontend service CPU below 40% and decrease instances number"

  alarm_actions = [
      aws_sns_topic.cpu_alarm_topic.arn,
      aws_autoscaling_policy.reduce_instances.arn
  ]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_autoscaling_notification" "asg_notifications" {
  group_names = [aws_autoscaling_group.asg.name]
  
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ]

  topic_arn = aws_sns_topic.cpu_alarm_topic.arn
}
