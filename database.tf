#create a security group for RDS Database Instance
resource "aws_security_group" "dcb_rds_sg" {
  name = "test_sg"
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#create a RDS Database Instance
resource "aws_db_instance" "myinstance" {
  engine               = "mysql"
  identifier           = "myrdsinstance"
  allocated_storage    =  20
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = "myrdspasswordtest"
  parameter_group_name = "default.mysql5.7"
  vpc_security_group_ids = ["sg-03b018979d4468388"]
  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true
  backup_retention_period     = 35
  skip_final_snapshot  = true
  publicly_accessible =  true

  tags = {
    Name = "testmysql"
 }
}


resource "aws_lb_target_group" "dcbelb" {
  name     = "test"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0c1dcfb31cbb1a395"
  target_type = "instance"
 
  tags = {
    Name = "test-tg"
 }
}

resource "aws_elb" "dcb-elb" {
  name               = "test-elb"
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }
  instances                   = ["i-00303f6a963c9f16b"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
  tags = {
    Name = "test-elb"
  }
}
