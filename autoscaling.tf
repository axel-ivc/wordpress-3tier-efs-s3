###############################################################################
# LAUNCH TEMPLATE
###############################################################################

# Inject variables into user data script
data "template_file" "ec2app_user_data" {
  template = file("${path.module}/ec2app_user_data.tftpl")
  vars = {
    EFS_ID = aws_efs_file_system.WP01-EFS.id
  }
}

# Select the newest AMI with Amazon Linux 2
data "aws_ami" "AmazonLinuxAPP" {
  most_recent = true
  owners      = ["137112412989"] # Amazon
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.*-x86_64-gp2"]
  }
}

# Template for APP layer
resource "aws_launch_template" "WP01-LT" {
  name                   = "WP01-LT"
  update_default_version = true
  instance_type          = var.WP01_INST_TYPE
  image_id               = data.aws_ami.AmazonLinuxAPP.id
  key_name               = aws_key_pair.WebApps-KeyPair.key_name
  user_data              = base64encode(data.template_file.ec2app_user_data.rendered)
  vpc_security_group_ids = [aws_security_group.WebApps-SGprivate.id]

  instance_initiated_shutdown_behavior = "terminate"

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name  = "WP01-EC2app"
      Scope = var.TAG_SCOPE
      Env   = var.TAG_ENV
    }
  }

  tags = { Name = "WP01-LT" }
}

###############################################################################
# LOAD BALANCING
###############################################################################

# Target group
resource "aws_lb_target_group" "WP01-TG" {
  name     = "WP01-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.WebApps-vpc.id

  health_check {
    matcher = "200,302"
  }

  tags = { Name = "WP01-ALB" }
}

# ALB
resource "aws_lb" "WP01-ALB" {
  name               = "WP01-ALB"
  internal           = false
  load_balancer_type = "application"
  enable_http2       = false
  security_groups    = [aws_security_group.WebApps-SGpublic.id]
  subnets            = [aws_subnet.WebApps-SubNpublic[0].id, aws_subnet.WebApps-SubNpublic[1].id]

  tags = { Name = "WP01-ALB" }
}

# ALB listener for target group
resource "aws_lb_listener" "WP01-ALBlistener" {
  load_balancer_arn = aws_lb.WP01-ALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.WP01-TG.arn
  }

  tags = { Name = "WP01-ALBlistener" }
}

###############################################################################
# AUTOSCALING
###############################################################################

# Autoscaling group from launch template
resource "aws_autoscaling_group" "WP01-ASG" {
  name              = "WP01-ASG"
  max_size          = var.WP01_ASG_MAX_INST
  min_size          = var.WP01_ASG_MIN_INST
  desired_capacity  = var.WP01_ASG_MIN_INST
  health_check_type = "ELB"
  default_cooldown  = 300
  target_group_arns = [aws_lb_target_group.WP01-TG.arn]

  # Create instances in one AZ to avoid paid cross-zones traffic
  vpc_zone_identifier = [aws_subnet.WebApps-SubNprivate["APPa"].id]
  # Multiple AZs
  #vpc_zone_identifier = [for SubN in keys(var.VPC_PRIVATE_SUBNETS) : aws_subnet.WebApps-SubNprivate["${SubN}"].id
  #if replace(SubN, "/.$/", "") == "APP"]

  launch_template {
    id      = aws_launch_template.WP01-LT.id
    version = aws_launch_template.WP01-LT.latest_version
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Scale OUT policy
resource "aws_autoscaling_policy" "WP01-ASpolicyOUT" {
  name                   = "WP01-ASpolicyOUT"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.WP01-ASG.name
}

resource "aws_cloudwatch_metric_alarm" "WebApps-alarmASpolicyOUT" {
  alarm_name          = "webapps-alarmaspolicyout"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "ASG CPU utilization for scaling OUT"
  alarm_actions       = [aws_autoscaling_policy.WP01-ASpolicyOUT.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.WP01-ASG.name
  }
  insufficient_data_actions = []

  tags = { Name = "WebApps-alarmASpolicyOUT" }
}

# Scale IN policy
resource "aws_autoscaling_policy" "WP01-ASpolicyIN" {
  name                   = "WP01-ASpolicyIN"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.WP01-ASG.name
}

resource "aws_cloudwatch_metric_alarm" "WebApps-alarmASpolicyIN" {
  alarm_name          = "webapps-alarmaspolicyin"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "ASG CPU utilization for scaling IN"
  alarm_actions       = [aws_autoscaling_policy.WP01-ASpolicyIN.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.WP01-ASG.name
  }
  insufficient_data_actions = []

  tags = { Name = "WebApps-alarmASpolicyIN" }
}