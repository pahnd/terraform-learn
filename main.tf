terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~>3.0"
      }
    }
}

provider "aws" {
    region = "eu-central-1"
}

#Create a VPC
resource "aws_vpc" "vpc_block" {
  cidr_block = var.vpc_cidr_block
  tags = {
    "Name" = "Production ${var.main_vpc_name}" 
  }
}

#Create a subnet in the VPC
resource "aws_subnet" "project_public_subnet" {
    vpc_id = aws_vpc.vpc_block.id
    cidr_block = var.web_subnet
    availability_zone = var.subnet_zone
    tags = {
        "Name" = "web_subnet"
    }
}

#Create an Internet Gateway (IGW)
resource "aws_internet_gateway" "project_igw" {
    vpc_id = aws_vpc.vpc_block.id
    tags = {
        "Name" = "${var.main_vpc_name} IGW"
    }
}

#Associate the Internet Gateway to the default Route Table (RT)
resource "aws_default_route_table" "project_vpc_default_rt" {
    default_route_table_id = aws_vpc.vpc_block.default_route_table_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.project_igw.id
    }
    tags = {
        "Name" = "project-default-route-table"
    }
}

resource "aws_default_security_group" "project_sec_group_default" {
    vpc_id = aws_vpc.vpc_block.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        # cidr_blocks = ["0.0.0.0/0"]
        cidr_blocks = [var.my_public_ip]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    engress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tag = {
        "Name" = "project-default-security-group"
    }
}