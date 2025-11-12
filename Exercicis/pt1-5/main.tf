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

# tabla de rutas de subredes publicas
resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.main.id 

  route {
    cidr_block = "0.0.0.0/0"
    Gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Asociar cada subnet publica
resource "aws_route_table_association" "public_subnets" {
  count          = var.subnet_count
  subnet_id      = aws_submet.public[count.index].id
  route_table_id = aws_route_table.public.id 
}

#grupo de seguridad
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-sg"
  description = "Security Group per a instàncies EC2"
  vpc_id      = aws_vpc.main.id
   
  # Permet HTTP des de qualsevol IP
  ingress {
    description = "Permet HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permet SSH només des de la IP definida (institut o casa)
  ingress {
    description = "Permet SSH des de IP definida"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Permet ICMP només des de dins la VPC
  ingress {
    description = "Permet ICMP només des de la VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Permet tot el tràfic sortint
  egress {
    description = "Permet tot el tràfic sortint"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}