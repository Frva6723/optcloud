# ssh_config.tpl

# Configuración para el Bastion Host
Host bastion
  Hostname ${bastion_public_ip}
  User ec2-user
  IdentityFile ~/.ssh/bastion.pem
  StrictHostKeyChecking no
  # Permite al SSH Agent reenviar claves, útil si necesitas acceder más allá del bastión
  ForwardAgent yes

# Configuración para las instancias privadas (ProxyJump)
# Bucle que itera sobre el número de instancias privadas
%{ for i in range(private_instance_count) ~}
Host private-${i + 1}
  # Hostname es la IP privada del servidor (a la que se accede a través del túnel)
  Hostname ${private_ips[i]}
  User ec2-user
  # Clave privada correspondiente a esta instancia
  IdentityFile ~/.ssh/private-${i + 1}.pem
  # Configuración esencial: utiliza la conexión 'bastion' como túnel
  ProxyJump bastion
  StrictHostKeyChecking no
%{ endfor ~}