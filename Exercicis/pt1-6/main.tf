# main.tf - Parte 1: Red y Data Sources

# Gets the list of available azs in the defined region.
data "aws_availability_zones" "available" {
  state = "available"
}

# Variable local para las AZs, simplifica el acceso por índice
locals {
  azs = data.aws_availability_zones.available.names
}

# ---------- VPC ----------
# Defines the main Virtual Private Cloud.
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name    = "${var.project_name}_main_vpc"
    Project = var.project_name
  }
}

# ---------- SUBNETS ----------
# Subred Pública
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = local.azs[0]
  cidr_block              = var.public_subnet_cidr_base # 10.0.1.0/24
  map_public_ip_on_launch = true
  tags = {
    Name    = "${var.project_name}_public_subnet_a"
    Project = var.project_name
  }
}

# Subredes Privadas (USANDO COUNT)
resource "aws_subnet" "private_subnet" {
  count                   = var.private_instance_count
  vpc_id                  = aws_vpc.main.id
  # Rotación entre AZs usando el índice de count
  availability_zone       = local.azs[count.index % length(local.azs)]
  # Cálculo del CIDR: 10.0.2.0/24, 10.0.3.0/24, ...
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index + 2)
  tags = {
    Name    = "${var.project_name}_private_${count.index + 1}_${local.azs[count.index % length(local.azs)]}"
    Project = var.project_name
  }
}

# ---------- INTERNET GATEWAY ----------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "${var.project_name}_iwg"
    Project = var.project_name
  }
}

# ---------- ELASTIC IPs ----------
resource "aws_eip" "ngtw_eip" {
  domain = "vpc"
}

resource "aws_eip" "bastion_eip" {
  domain = "vpc"
}

# ---------- NAT Gateway ----------
resource "aws_nat_gateway" "ngtw" {
  allocation_id = aws_eip.ngtw_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.igw]
}

# ---------- ROUTE TABLE ----------
# Tabla Pública (Ruta a IGW)
resource "aws_route_table" "rt_tbl_public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name    = "${var.project_name}_rt_public"
    Project = var.project_name
  }
}

# Tabla Privada (Ruta a NAT Gateway) - Se necesita una sola, asociada a todas las subredes
resource "aws_route_table" "rt_tbl_private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngtw.id
  }
  tags = {
    Name    = "${var.project_name}_rt_private"
    Project = var.project_name
  }
}

# ---------- ROUTING TABLE ASSOCIATIONS ----------
resource "aws_route_table_association" "rta_public" {
  route_table_id = aws_route_table.rt_tbl_public.id
  subnet_id      = aws_subnet.public_subnet.id
}

# Asociaciones de Subredes Privadas (USANDO COUNT)
resource "aws_route_table_association" "rta_private" {
  count          = var.private_instance_count
  route_table_id = aws_route_table.rt_tbl_private.id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}

# ==============================================================================
# Parte 2: Security Groups (Corregido el Ciclo y la Sintaxis)
# ==============================================================================

resource "aws_security_group" "sg_bastion" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "${var.project_name}_sg_bastion"
    Project = var.project_name
  }
  ingress {
    description = "Allow SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }
  egress {
    description = "Allow all outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "${var.project_name}_sg_private"
    Project = var.project_name
  }
  ingress {
    description = "Allow SSH from itself"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
  }
  egress {
    description = "Allow any outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# (Reglas Separadas para Romper el Ciclo - ESTO DEBE QUEDAR IGUAL)
resource "aws_security_group_rule" "private_sg_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_bastion.id
  security_group_id        = aws_security_group.sg_private.id
}

resource "aws_security_group_rule" "bastion_sg_ssh_to_private" {
  type                     = "egress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_private.id
  security_group_id        = aws_security_group.sg_bastion.id
}

# ==============================================================================
# Parte 3: Claves y EC2
# ==============================================================================

resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_key_pair" {
  key_name   = "${var.project_name}-bastion-key"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

resource "local_file" "bastion_pem" {
  filename        = "bastion.pem"
  content         = tls_private_key.bastion_key.private_key_pem
  file_permission = "400"
}

resource "tls_private_key" "private_instance_key" {
  count     = var.private_instance_count
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "private_instance_key_pair" {
  count      = var.private_instance_count
  public_key = tls_private_key.private_instance_key[count.index].public_key_openssh
  key_name   = "${var.project_name}-private-${count.index + 1}"
}

resource "local_file" "private_instance_pem" {
  count           = var.private_instance_count
  filename        = "private-${count.index + 1}.pem"
  content         = tls_private_key.private_instance_key[count.index].private_key_pem
  file_permission = "400"
}

# ---------- EC2 INSTANCES ----------
# Instancia Bastion (sin count)
resource "aws_instance" "bastion_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  key_name                    = aws_key_pair.bastion_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.sg_bastion.id]
  associate_public_ip_address = true
  tags = {
    Name    = "${var.project_name}-bastion-instance"
    Project = var.project_name
  }
}

resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id   = aws_instance.bastion_instance.id
  allocation_id = aws_eip.bastion_eip.id
}

# Servidores Privados (USANDO COUNT)
resource "aws_instance" "private_instance" {
  count                       = var.private_instance_count
  ami                         = var.ami_id
  instance_type               = var.instance_type
  # Asigna cada instancia a su subred correspondiente
  subnet_id                   = aws_subnet.private_subnet[count.index].id
  key_name                    = aws_key_pair.private_instance_key_pair[count.index].key_name
  vpc_security_group_ids      = [aws_security_group.sg_private.id]
  associate_public_ip_address = false
  tags = {
    Name    = "${var.project_name}-private-instance-${count.index + 1}"
    Project = var.project_name
  }
}

# ---------- SSH CONFIG GENERATION ----------
resource "local_file" "ssh_config_file" {
  filename = "ssh_config_per_connect.txt"

  content = templatefile("ssh_config.tpl", {
    bastion_public_ip      = aws_eip.bastion_eip.public_ip
    # Accede a las IPs privadas usando el splat (*) con count
    private_ips            = aws_instance.private_instance.*.private_ip
    private_instance_count = var.private_instance_count
  })
}

# ---------- S3 BUCKET ----------
# ... (Esta parte permanece idéntica a la anterior)

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "keys_backup_bucket" {
  bucket = "${var.project_name}-keys-backup-bucket-${random_id.suffix.hex}"

  tags = {
    Name    = "${var.project_name}_key_backup_bucket"
    Project = var.project_name
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_ownership" {
  bucket = aws_s3_bucket.keys_backup_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_object" "bastion_pk_backup" {
  bucket                 = aws_s3_bucket.keys_backup_bucket.id
  key                    = "bastion.pub"
  content                = tls_private_key.bastion_key.public_key_openssh
  server_side_encryption = "AES256"
}

resource "aws_s3_object" "private_instance_pk_backup" {
  count  = var.private_instance_count
  bucket = aws_s3_bucket.keys_backup_bucket.id
  key    = "private-${count.index + 1}.pub"
  content = tls_private_key.private_instance_key[count.index].public_key_openssh
  server_side_encryption = "AES256"
}