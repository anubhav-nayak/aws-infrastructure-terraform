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
  cidr_block              = var.jump_server_subnet["cidr_block"]
  availability_zone       = var.jump_server_subnet["availability_zone"]
  map_public_ip_on_launch = true

  tags = {
    Name = "jump-server-subnet"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

resource "aws_route_table" "public_lb_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public-lb-route-table"
  }
}

resource "aws_route_table_association" "public_lb_subnet_associations" {
  for_each = aws_subnet.public_lb_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_lb_route_table.id
}

resource "aws_route_table" "jump_server_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "jump-server-route-table"
  }
}

resource "aws_route_table_association" "jump_server_subnet_association" {
  subnet_id      = aws_subnet.jump_server_subnet.id
  route_table_id = aws_route_table.jump_server_route_table.id
}

resource "aws_route_table" "private_db_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "private-db-route-table"
  }
}

resource "aws_route_table_association" "private_db_subnet_associations" {
  for_each = aws_subnet.private_db_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db_route_table.id
}

resource "aws_route_table" "private_app_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "private-app-route-table"
  }
}

resource "aws_route_table_association" "private_app_subnet_associations" {
  for_each = aws_subnet.private_app_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app_route_table.id
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP traffic from the internet to the Application Load Balancer"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "Allow HTTP traffic from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_security_group" "jump_server_sg" {
  name        = "jump-server-sg"
  description = "Allow SSH access to the jump server from the administrator"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "Allow SSH access from the administrator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jump-server-sg"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow HTTP traffic from ALB and SSH access from the jump server"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description     = "Allow HTTP traffic from the ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "Allow SSH access from the jump server"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jump_server_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-sg"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Allow MySQL traffic only from application instances"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description     = "Allow MySQL traffic from application instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}
