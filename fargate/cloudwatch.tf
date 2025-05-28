resource "aws_sns_topic" "cpu_alarm_topic" {
  name = "cpu-alarm-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.cpu_alarm_topic.arn
  protocol  = "email"
  endpoint  = "276751@student.pwr.edu.pl"
}

resource "aws_cloudwatch_metric_alarm" "backend_cpu_alarm" {
  alarm_name          = "backend-fargate-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70 
  alarm_description   = "Alarm when ECS backend service CPU exceeds 70%"
  alarm_actions       = [aws_sns_topic.cpu_alarm_topic.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.backend_service.name
  }
}

resource "aws_cloudwatch_metric_alarm" "frontend_cpu_alarm" {
  alarm_name          = "frontend-fargate-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alarm when ECS frontend service CPU exceeds 70%"
  alarm_actions       = [aws_sns_topic.cpu_alarm_topic.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.frontend_service.name
  }
}