resource "aws_vpc" "dcb_vpc" {
  cidr_block = "15.0.0.0/16"

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
  cidr_block        = "15.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name  = "test_subnet_private_1"
  }
}

resource "aws_subnet" "dcb_subnet_private_2" {
  vpc_id            = aws_vpc.dcb_vpc.id
  cidr_block        = "15.0.2.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name  = "test_subnet_private_2"
  }
}

resource "aws_subnet" "dcb_subnet_public_1" {
  vpc_id                  = aws_vpc.dcb_vpc.id
  cidr_block              = "15.0.101.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"
  tags = {
    Name  = "test_subnet_public_1"
  }
}

resource "aws_subnet" "dcb_subnet_public_2" {
  vpc_id                  = aws_vpc.dcb_vpc.id
  cidr_block              = "15.0.102.0/24"
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

resource "aws_security_group" "test-sg" {
  vpc_id = aws_vpc.dcb_vpc.id
  name   = "test-grp"
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
    cidr_blocks = ["0.0.0.0/0"]
  }

tags = {
  Name = "test-grp"
 }
}

