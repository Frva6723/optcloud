# --- Salida de las instancias públicas ---
output "publica_instance_ids" {
  description = "Identificadores (ID) de las instancias EC2 públicas"
  value       = aws_instance.publica[*].id
}

output "publica_instance_public_ips" {
  description = "Direcciones IP públicas de las instancias EC2 públicas"
  value       = aws_instance.publica[*].public_ip
}

output "publica_instance_private_ips" {
  description = "Direcciones IP privadas de las instancias EC2 públicas"
  value       = aws_instance.publica[*].private_ip
}

# --- Salida de las instancias privadas ---
output "private_instance_ids" {
  description = "Identificadores (ID) de las instancias EC2 privadas"
  value       = aws_instance.privada[*].id
}

output "private_instance_private_ips" {
  description = "Direcciones IP privadas de las instancias EC2 privadas"
  value       = aws_instance.privada[*].private_ip
}

# --- Salida del bucket S3 (si se ha creado) ---
output "s3_bucket_name" {
  description = "Nombre del bucket S3 si se ha creado"
  value       = var.create_s3_bucket ? aws_s3_bucket.project_bucket[0].bucket : null
}