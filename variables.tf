variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.10.10.0/24"
}

variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "public_lb_subnets" {
  type = map(string)

  default = {
    "us-east-1a" = "10.10.10.128/27"
    "us-east-1b" = "10.10.10.160/27"
    "us-east-1c" = "10.10.10.224/27"
  }
}

variable "private_app_subnets" {
  type = map(string)

  default = {
    "us-east-1a" = "10.10.10.64/28"
    "us-east-1b" = "10.10.10.80/28"
    "us-east-1c" = "10.10.10.96/28"
  }
}

variable "private_db_subnets" {
  type = map(string)

  default = {
    "us-east-1a" = "10.10.10.0/28"
    "us-east-1b" = "10.10.10.16/28"
    "us-east-1c" = "10.10.10.32/28"
  }
}

variable "jump_server_subnet_cidr" {
  type    = string
  default = "10.10.10.192/28"
}

variable "jump_server_subnet_availability_zone" {
  type    = string
  default = "us-east-1a"
}
