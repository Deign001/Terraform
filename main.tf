terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}
# Create a VPC
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "2Tier"
  }
}
# Create a Load Balancer
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
  security_groups    = [aws_security_group.albsg.id]
}
# Create Security Group
# https://registry.terraform.io/providers/hashicorp/aws/3.3.0/docs/resources/security_group
resource "aws_security_group" "albsg" {
  name        = "albsg"
  description = "security group for alb"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Creates LB Security Group
# https://registry.terraform.io/providers/hashicorp/aws/3.3.0/docs/resources/lb_target_group
resource "aws_lb_target_group" "tg" {
  name     = "projecttg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  depends_on = [aws_vpc.main]
}
# Create LB Target Group
# https://registry.terraform.io/providers/hashicorp/aws/3.3.0/docs/resources/lb_target_group_attachment
resource "aws_lb_target_group_attachment" "tgattach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web_tier1.id
  port             = 80

  depends_on = [aws_instance.web_tier1]
}
# Create LB Target Group
# https://registry.terraform.io/providers/hashicorp/aws/3.3.0/docs/resources/lb_target_group_attachment
resource "aws_lb_target_group_attachment" "tgattach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web_tier2.id
  port             = 80

  depends_on = [aws_instance.web_tier2]
}
# Create LB Listener
#https://registry.terraform.io/providers/hashicorp/aws/3.3.0/docs/resources/lb_listener
resource "aws_lb_listener" "listenerlb" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Create Public Subnet
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public1"
  }
}
# Create Public Subnet
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public2"
  }
}
# Create Private Subnet
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "private1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private1"
  }
}
# Create Private Subnet
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "private2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private2"
  }
}
# Create Subnet Group
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group
resource "aws_db_subnet_group" "sub_4_db" {
  name       = "sub_4_db"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]
  tags = {
    Name = "My DB subnet group"
  }
}
# Create Internet Gateway
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway_attachment
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}
# Create Route Table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table#route
resource "aws_route_table" "Web_Tier" {
  tags = {
    Name = "Web_Tier"
  }
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}
# Create Route Table Association
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association#subnet_id
resource "aws_route_table_association" "Web_tier" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.Web_Tier.id
}
# Create Route Table Association
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association#subnet_id
resource "aws_route_table_association" "Web_tier2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.Web_Tier.id
}
# Create Route Table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table#route
resource "aws_route_table" "DB_Tier" {
  tags = {
    Name = "DB_Tier"
  }
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}
# Create Elastic IP Address
#https://hands-on.cloud/terraform-managing-aws-vpc-creating-private-subnets/
resource "aws_eip" "nat_eip" {
  vpc = true
}
# Create NAT Gateway
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway
resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public2.id
}
# Create Route Nat Route
#https://registry.terraform.io/providers/hashicorp/aws/3.3.0/docs/data-sources/route_table
resource "aws_route_table" "my_public2_nated" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }

  tags = {
    Name = "Main Route Table for NAT- subnet"
  }
}
# Create Route Table Association
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association#subnet_id
resource "aws_route_table_association" "my_public2_nated1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.my_public2_nated.id
}
resource "aws_route_table_association" "my_public2_nated2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.my_public2_nated.id
}
# Creates Public Security Group
# https://registry.terraform.io/providers/hashicorp/aws/3.3.0/docs/resources/security_group
resource "aws_security_group" "web_tier" {
  name        = "web_tier"
  description = "web and SSH allowed"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#Creates EC2 Instance
#linux2AMI
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instance
resource "aws_instance" "web_tier1" {
  ami                         = "ami-090fa75af13c156b4"
  key_name          	      = "launchtime"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public1.id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.web_tier.id]
  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "<html><body><h1>Web Tier 1, Success!</h1></body></html>" > /var/www/html/index.html
        EOF
}
#Creates EC2 Instance
#https://registry.terraform.io/providers/hashicorp/aws/3.3.0/docs/data-sources/instance
resource "aws_instance" "web_tier2" {
  ami                         = "ami-090fa75af13c156b4"
  key_name 		      = "launchtime"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public2.id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.web_tier.id]
  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "<html><body><h1>Web Tier 2, Success!</h1></body></html>" > /var/www/html/index.html
        EOF
}
#Creates RDS DB Instance
#https://registry.terraform.io/providers/hashicorp/aws/3.3.0/docs/resources/db_instance
resource "aws_db_instance" "the_db" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  db_subnet_group_name   = aws_db_subnet_group.sub_4_db.id
  vpc_security_group_ids = [aws_security_group.db_tier.id]
  name                   = "the_db"
  username               = "username"
  password               = "password"
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
}
#Creates Private Security Group
# https://registry.terraform.io/providers/hashicorp/aws/3.3.0/docs/resources/db_security_group
resource "aws_security_group" "db_tier" {
  name        = "db_sg"
  description = "allow traffic from Web Tier & SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/16"]
    security_groups = [aws_security_group.web_tier.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}
