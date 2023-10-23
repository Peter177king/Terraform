terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.76.1"
    }
  }
}

provider "aws" {
    region     = "us-east-2"
    access_key = "AKIAZSXQKNHKKVGJRW5M"
    secret_key = "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"
}


resource "aws_vpc" "dcb_vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "test"
  }
}

resource "aws_internet_gateway" "dcb_gw" {
  vpc_id = aws_vpc.dcb_vpc.id

  tags = {
    Name  = "test_gw"
  }
}


resource "aws_subnet" "dcb_subnet_private_1" {
  vpc_id            = aws_vpc.dcb_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name  = "test_subnet_private_1"
  }
}

resource "aws_subnet" "dcb_subnet_private_2" {
  vpc_id            = aws_vpc.dcb_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name  = "test_subnet_private_2"
  }
}

resource "aws_subnet" "dcb_subnet_public_1" {
  vpc_id                  = aws_vpc.dcb_vpc.id
  cidr_block              = "10.0.101.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"
  tags = {
    Name  = "test_subnet_public_1"
  }
}

resource "aws_subnet" "dcb_subnet_public_2" {
  vpc_id                  = aws_vpc.dcb_vpc.id
  cidr_block              = "10.0.102.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2b"
  tags = {
    Name  = "test_subnet_public_2"
  }
}

resource "aws_route_table" "dcb_rt_public" {
  vpc_id = aws_vpc.dcb_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dcb_gw.id
  }

  tags = {
    Name  = "test-rt-public"
  }
}

resource "aws_route_table_association" "test_rta_public_1" {
  subnet_id      = aws_subnet.dcb_subnet_public_1.id
  route_table_id = aws_route_table.dcb_rt_public.id
}
resource "aws_route_table_association" "test_rta_public_2" {
  subnet_id      = aws_subnet.dcb_subnet_public_2.id
  route_table_id = aws_route_table.dcb_rt_public.id
}

resource "aws_eip" "dcb-eip" {
  vpc      = true
  tags = {
    "Name" = "test-eip"
  }
}

resource "aws_nat_gateway" "dcb-nat" {
  allocation_id = "eipalloc-0ff30049c38c90364"
  subnet_id     = "subnet-0bbb9d536a2b66692"
  tags = {
    Name = "test-nat"
  }
}

resource "aws_route_table" "dcb_rt_private" {
  vpc_id = aws_vpc.dcb_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "nat-0c4aae84d9718ca7d"
  }

  tags = {
    Name = "test-rt-private"
  }
}

resource "aws_route_table_association" "dcb-rt-private_1" {
  subnet_id      = "subnet-0bbb9d536a2b66692"
  route_table_id = "rtb-0425f4c42817b544b"
}

resource "aws_route_table_association" "dcb_rt_private_2" {
  subnet_id      = "subnet-01508574cd3b5383a"
  route_table_id = "rtb-0425f4c42817b544b"
}

resource "aws_security_group" "test-sg" {
  name = "test-grp"
  description = "Allow HTTP, SSH and MYSQLAURORA traffic via Terraform"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks  = ["0.0.0.0/0"]
}

 tags = {
    Name = "test-grp"
 }
}

resource "aws_instance" "test-server" {
    ami               = "ami-0b1bd1fa4ba5756a3"
    count             = "1"
    instance_type     = "t2.micro"
    key_name          = "yum"
    vpc_security_group_ids  = ["sg-0d2e01ba53a2b0c0e"]
    tags = {
      Name = "test-server"
 }
}

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
  name                 = "testmysql"
  username             = "admin"
  password             = "myrdspasswordtest"
  parameter_group_name = "default.mysql5.7"
  vpc_security_group_ids = ["sg-0d2e01ba53a2b0c0e"]
  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true
  backup_retention_period     = 35
  skip_final_snapshot  = true
  publicly_accessible =  true

  tags = {
    Name = "testmysql"
 }
}

resource "aws_s3_bucket" "dcb" {

  bucket = "dcb-s3-bucket"

  acl    = "private"
 
  tags = {
    Name = "dcb-s3"
 }
}

resource "aws_lb_target_group" "dcbelb" {
  name     = "test"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0ce0c82ecce215ec4"
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
  instances                   = ["i-0d4f879a49439e969"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
  tags = {
    Name = "test-elb"
  }
}

