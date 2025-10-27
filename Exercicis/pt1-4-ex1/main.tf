provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "vpc_03" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC-03"
  }
}

# Subred pública A
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.vpc_03.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet-A"
  }
}

# Subred pública B
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.vpc_03.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet-B"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc_03.id
}

# Tabla de rutas pública
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_03.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Public-Route"
  }
}

# Asociaciones de tabla de rutas
resource "aws_route_table_association" "public_a_assoc" {
  subnet_id         = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_b_assoc" {
  subnet_id         = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

#Grupo de seguridad
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Permite SSH global, ICMP interno y trafico saliente"
  vpc_id      = aws_vpc.vpc_03.id
  
  ingress {
    description = "SSH desde cualquier lugar"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP desde la VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Instancia EC2 en Subred A
resource "aws_instance" "ec2_a" {
  ami                    = "ami-052064a798f08f0d3" # Amazon Linux 2023
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_a.id
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "ec2-a"
  }
}

# Instancia EC2 en Subred B
resource "aws_instance" "ec2_b" {
  ami                    = "ami-052064a798f08f0d3"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_b.id
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "ec2-b"
  }
}