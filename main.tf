resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "public_lb_subnets" {
  for_each = var.public_lb_subnets

  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "public-lb-${each.key}"
  }
}

resource "aws_subnet" "private_app_subnets" {
  for_each = var.private_app_subnets

  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "private-app-${each.key}"
  }
}

resource "aws_subnet" "private_db_subnets" {
  for_each = var.private_db_subnets

  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "private-db-${each.key}"
  }
}

resource "aws_subnet" "jump_server_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.jump_server_subnet_cidr
  availability_zone       = var.jump_server_subnet_availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "jump-server-subnet"
  }
}
