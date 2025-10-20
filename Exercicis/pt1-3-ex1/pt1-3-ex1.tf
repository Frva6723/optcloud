# configurar el provedor
provider "aws" {
    region = "us-east-1"
}

# crear instancia de EC2
resource "aws_instance" "amazon_linux_2023" {
  count         = 2
  ami           = "ami-0c101f26f147fa7fd" # Amazon Linux 2023 (us-east-1)
  instance_type = "t3.micro"

  tags = {
    Name = "amazon-linux-2023-${count.index}"
  }
}