# outputs.tf

# Dirección IP pública del Bastion Host
output "bastion_public_ip" {
  description = "IP Pública del Bastion Host"
  value       = aws_eip.bastion_eip.public_ip
}

# Comando de conexión de ejemplo
output "ssh_commands" {
  description = "Ejemplo de comandos para conectar a las instancias"
  value = {
    bastion   = "ssh bastion"
    private_1 = "ssh private-1"
    private_n = "ssh private-N (N = 1 a ${var.private_instance_count})"
  }
}