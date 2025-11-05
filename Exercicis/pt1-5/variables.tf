variable "region" {
    description = "valor para la region de aws"
    type = string
    default = "us-east-1"
}

variable "project_name" {
    description = "Nombre para el proyecto"
    type = string
    default = "terraform-project"
}

variable "instance_count" {
    description = "Numero de instancias por subnet"
    type = number
    default = 8
}

variable "subnet_count" {
    description = "Numero de subnet por tipo"
    type = number
    default = 2
}
variable "instance_type" {
    description = "Definir el tipo de las instancias"
    type = string
    default = "t3.micro"
}

variable "instance_ami" {
    description = "Ami para las intancias EC2"
    type = string
    default = "ami-052064a798f08f0d3"
}

variable "create_s3_bucket" {
    description = "Indica si se debe crear un bucket S3"
    type = bool
    default = true
}

variable "vpc_cidr" {
    description = "CIDR de la VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "my_ip" {
    description = "IP para conexiones SSH"
    type = string
    default = "0.0.0.0/0"
}