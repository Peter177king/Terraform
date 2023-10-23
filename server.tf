resource "aws_instance" "test-server" {
    ami               = "ami-00dc7bfd5dab3decb"
    count             = "1"
    instance_type     = "t2.micro"
    subnet_id            = "subnet-0b82be94cbfda5c4e"
    key_name          = "yum"
    tags = {
      Name = "test-server"
 }
}

resource "aws_lb" "test_alb" {
  name               = "test-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-03b018979d4468388"]
  subnets            = ["subnet-0b82be94cbfda5c4e", "subnet-07af44f4b6804cd2c"]
}


resource "aws_lb_target_group" "test_tg" {
  name     = "test-tg"
  target_type = "instance"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = "vpc-0c1dcfb31cbb1a395"
}

resource "aws_lb_listener" "test_lb_listener" {
  load_balancer_arn = "arn:aws:elasticloadbalancing:us-east-2:658707737044:loadbalancer/app/test-alb/75604fb23bbae2b6"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "arn:aws:elasticloadbalancing:us-east-2:658707737044:targetgroup/test-tg/b60156d9dbe23d1b"
  }
}


resource "aws_launch_template" "test_launch_template" {

  name = "test_launch_template"

  image_id      = "ami-00dc7bfd5dab3decb"
  instance_type = "t2.micro"
  key_name      = "yum"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 10
      volume_type = "gp2"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = ["sg-03b018979d4468388"]
  }
}


resource "aws_autoscaling_group" "test_asg" {
  name                      = "test_asg"
  max_size                  = 0
  min_size                  = 0
  health_check_type         = "ELB"    # optional
  desired_capacity          = 0
  target_group_arns = ["arn:aws:elasticloadbalancing:us-east-2:658707737044:targetgroup/test-tg/b60156d9dbe23d1b"]

  vpc_zone_identifier       = ["subnet-0b82be94cbfda5c4e", "subnet-07af44f4b6804cd2c"]
  
  launch_template {
    id      = "lt-0060e10e0e7ddff4c"
    version = "$Latest"
  }
}


resource "aws_autoscaling_policy" "test_scale_up" {
  name                   = "test_scale_up"
  policy_type            = "SimpleScaling"
  autoscaling_group_name = "test_asg"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"      # add one instance
  cooldown               = "300"    # cooldown period after scaling
}


resource "aws_cloudwatch_metric_alarm" "test_scale_up_alarm" {
  alarm_name          = "test-scale-up-alarm"
  alarm_description   = "asg-scale-up-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "50"
  dimensions = {
    "AutoScalingGroupName" = "test_asg"
  }
  actions_enabled = true
  alarm_actions   = ["arn:aws:cloudwatch:us-east-2:658707737044:alarm:test-scale-up-alarm"]
}


resource "aws_autoscaling_policy" "test_scale_down" {
  name                   = "test-scale-down"
  autoscaling_group_name = "test_asg"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}


resource "aws_cloudwatch_metric_alarm" "test_scale_down_alarm" {
  alarm_name          = "test-asg-scale-down-alarm"
  alarm_description   = "asg-scale-down-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  dimensions = {
    "AutoScalingGroupName" = "test_asg"
  }
  actions_enabled = true
  alarm_actions   = ["arn:aws:cloudwatch:us-east-2:658707737044:alarm:test-asg-scale-down-alarm"]
}
