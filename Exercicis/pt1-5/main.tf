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
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Asociar cada subnet publica
resource "aws_route_table_association" "publica_subnets" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.publica[count.index % var.subnet_count].id
  route_table_id = aws_route_table.publica.id 
}

#grupo de seguridad
resource "aws_security_group" "ec2-sg" {
  name        = "${var.project_name}-sg"
  description = "Security Group para las instancias EC2"
  vpc_id      = aws_vpc.main.id
   
  # Permet HTTP des de qualsevol IP
  ingress {
    description = "Permite HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permet SSH només des de la IP definida (institut o casa)
  ingress {
    description = "Permite SSH desde la IP definida"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Permet ICMP només des de dins la VPC
  ingress {
    description = "Permite ICMP solo desde la VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Permite todo el trafico salga
  egress {
    description = "Permite todo el trafico salga"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# instancias EC2 publicas
resource "aws_instance" "public" {
  count         = var.subnet_count * var.instance_count
  ami           = var.instance_ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.publica[count.index % var.subnet_count].id
  security_groups = [aws_security_group.ec2-sg.name]

  tags = {
    Name = "${var.project_name}-publica-${count.index}"
  }

  # Asegura que el IGW esté creado antes de lanzar las instancias públicas.
  depends_on = [aws_internet_gateway.igw]
}

#intancias EC2 Privadas
resource "aws_instance" "private" {
  count         = var.subnet_count * var.instance_count
  ami           = var.instance_ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.privada[count.index % var.subnet_count].id
  security_groups = [aws_security_group.ec2-sg.name]

  tags = {
    Name = "${var.project_name}-privada-${count.index}"
  }
}

# Bucket S3 condicional
resource "aws_s3_bucket" "project_bucket" {
  count  = var.create_s3_bucket ? 1 : 0 # Esta linea lo que hace es que si la variable es ture crea 1 bucket si es falsa no la crea
  bucket = "${var.project_name}-bucket"

  tags = {
    Name = "${var.project_name}-bucket"
  }
}