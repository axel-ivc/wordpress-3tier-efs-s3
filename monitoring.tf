# Note: 10 alarms MAX in Free-Tier

# SNS topic
resource "aws_sns_topic" "WebApps-WP01topic" {
  name = "webapps-wp01topic"
  tags = { Name = "WebApps-WP01topic" }
}

# Subscribe configured email address
resource "aws_sns_topic_subscription" "WebApps-subsME" {
  topic_arn                       = aws_sns_topic.WebApps-WP01topic.arn
  protocol                        = "email"
  endpoint                        = var.EMAIL_ALERTS
  confirmation_timeout_in_minutes = 5
}

# Autoscaling group notifications
resource "aws_autoscaling_notification" "WP01ASG-notify" {
  group_names = [aws_autoscaling_group.WP01-ASG.name]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.WebApps-WP01topic.arn
}

# ALB/Target group alarms
# Health instances count is less than configured minimum
resource "aws_cloudwatch_metric_alarm" "WebApps-alarmWP01TGhealth" {
  alarm_name          = "webapps-wp01tghealth"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Maximum"
  threshold           = var.WP01_ASG_MIN_INST
  actions_enabled     = "true"
  alarm_description   = "Target Group healthy instances count"
  alarm_actions       = [aws_sns_topic.WebApps-WP01topic.arn]
  ok_actions          = [aws_sns_topic.WebApps-WP01topic.arn]
  dimensions = {
    TargetGroup  = aws_lb_target_group.WP01-TG.arn_suffix
    LoadBalancer = aws_lb.WP01-ALB.arn_suffix
  }
  insufficient_data_actions = []

  tags = { Name = "WebApps-alarmWP01TGhealth" }
}

# RDS01 alarms

# CPU >= 80%
resource "aws_cloudwatch_metric_alarm" "WebApps-alarmRDS01CPU" {
  alarm_name          = "webapps-rds01cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  actions_enabled     = "true"
  alarm_description   = "RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.WebApps-WP01topic.arn]
  ok_actions          = [aws_sns_topic.WebApps-WP01topic.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds01.id
  }
  insufficient_data_actions = []

  tags = { Name = "WebApps-alarmRDS01CPU" }
}

# Swap >= 1GB
resource "aws_cloudwatch_metric_alarm" "WebApps-alarmRDS01SWAP" {
  alarm_name          = "webapps-rds01swap"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SwapUsage"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "1073741824"
  actions_enabled     = "true"
  alarm_description   = "RDS swap usage"
  alarm_actions       = [aws_sns_topic.WebApps-WP01topic.arn]
  ok_actions          = [aws_sns_topic.WebApps-WP01topic.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds01.id
  }
  insufficient_data_actions = []

  tags = { Name = "WebApps-alarmRDS01SWAP" }
}

# Free space <= 2GB
resource "aws_cloudwatch_metric_alarm" "WebApps-alarmRDS01SPACE" {
  alarm_name          = "webapps-rds01space"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "2147483648"
  actions_enabled     = "true"
  alarm_description   = "RDS free space"
  alarm_actions       = [aws_sns_topic.WebApps-WP01topic.arn]
  ok_actions          = [aws_sns_topic.WebApps-WP01topic.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds01.id
  }
  insufficient_data_actions = []

  tags = { Name = "WebApps-alarmRDS01SPACE" }
}