# VPC principal
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.project_name}-VPC"
  }
}

# Subnets publicas
resource "aws_subnet" "publica" {
    count       = var.subnet_count
    vpc_id      = aws_vpc.main.id
    cidr_block  = cidrsubnet(var.vpc_cidr, 8, count.index)
    map_public_ip_on_launch = true
    tags = {
      Name = "${var.project_name}-subnet-publica-${count.index}"
    }
}

# Subnets privadas
resource "aws_subnet" "privada" {
    count = var.subnet_count
    vpc_id = aws_vpc.main.id
    cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
    map_customer_owned_ip_on_launch = false
    tags = {
      Name = "${var.project_name}-subnet-privada-${count.index}"
    }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
    tags = {
      Name = "${var.project_name}-igw"
    }
}