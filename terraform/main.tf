terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# vars
variable "my_ip" {
  description = "My home public IP"
  type        = string
}

variable "availability_zone" {
  description = "AZ to deploy in"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

# VPC
resource "aws_vpc" "personal_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "personalWebsiteVPC"
  }
}

# subnet
resource "aws_subnet" "personal_subnet" {
  vpc_id            = aws_vpc.personal_vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 1)
  availability_zone = var.availability_zone
  tags = {
    Name = "personalWebsiteSubnet"
  }
}

# ig
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.personal_vpc.id
}

# route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.personal_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "publicRouteTable"
  }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.personal_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# security group
resource "aws_security_group" "instance_sg" {
  name   = "personalWebsiteSG"
  vpc_id = aws_vpc.personal_vpc.id

  ingress {
    description = "SSH only from home IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
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


resource "aws_instance" "personal_website" {
  ami                         = "ami-09e6f87a47903347c"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.personal_subnet.id
  vpc_security_group_ids      = [aws_security_group.instance_sg.id]
  associate_public_ip_address = true
  iam_instance_profile = "ec2LogRole"
  key_name                    = "zenKey"
  tags = {
    Name = "personalWebsite"
  }
}

# static ip
resource "aws_eip" "personal_eip" {
  instance = aws_instance.personal_website.id
  vpc      = true
}

# add a host zone to route53
data "aws_route53_zone" "personal_zone" {
  name = "onurhanak.com."
}

resource "aws_route53_record" "onurhanak_a" {
  zone_id = data.aws_route53_zone.personal_zone.zone_id
  name    = "" 
  type    = "A"
  ttl     = 300
  records = [aws_eip.personal_eip.public_ip]
}

# output public ip for ansible
output "instance_public_ip" {
  value = aws_eip.personal_eip.public_ip
}
