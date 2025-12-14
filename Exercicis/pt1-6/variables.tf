# variables.tf

variable "aws_region" {
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  default     = "frederick-cloud"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_base" {
  type        = string
  default     = "10.0.1.0/24"
}


variable "private_instance_count" {
  type        = number
  default     = 2
}

variable "allowed_ip" {
  type        = string
  default     = "0.0.0.0/0"
}


variable "ami_id" {
  type        = string
  default     = "ami-052064a798f08f0d3"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
}