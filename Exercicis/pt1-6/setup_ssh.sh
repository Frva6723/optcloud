#!/bin/bash
# setup_ssh.sh

# Nombre del proyecto para la delimitación en el archivo config
PROJECT_NAME="frederick-cloud-ra1" # Debe coincidir con el valor por defecto de project_name
# Directorio de configuración SSH local
SSH_DIR=~/.ssh
CONFIG_FILE="$SSH_DIR/config"
# Archivo de configuración generado por Terraform
CONFIG_TO_ADD="ssh_config_per_connect.txt"

echo " Comenzando la configuración local de SSH para $PROJECT_NAME..."

# 1. Crear el directorio ~/.ssh si no existe
mkdir -p "$SSH_DIR"

# 2. Mover claves .pem y asignar permisos (chmod 400)
echo " Moviendo claves .pem a $SSH_DIR/ y asignando permisos 400..."
# Busca todos los archivos .pem en el directorio actual y los mueve
find . -maxdepth 1 -name "*.pem" -exec mv {} "$SSH_DIR/" \;
# Asigna permisos solo de lectura al propietario (400)
chmod 400 "$SSH_DIR"/*.pem 2>/dev/null

# 3. Añadir la configuración de ProxyJump al archivo ~/.ssh/config
echo " Añadiendo configuración de ProxyJump a $CONFIG_FILE..."

# Eliminar entradas existentes de la práctica para evitar duplicados 
if [ -f "$CONFIG_FILE" ]; then
    # Usamos el nombre del proyecto como marcador de inicio/fin
    sed -i '/# Inicia configuracion frederick-cloud-ra1/,/# Fin configuracion frederick-cloud-ra1/d' "$CONFIG_FILE" 2>/dev/null
fi

# Añadir la nueva configuración delimitada
echo -e "\n# Inicia configuracion $PROJECT_NAME" >> "$CONFIG_FILE"
cat "$CONFIG_TO_ADD" >> "$CONFIG_FILE"
echo "# Fin configuracion $PROJECT_NAME" >> "$CONFIG_FILE"

echo " Configuración local completada."
echo "  Ahora puedes conectarte usando: 'ssh bastion' o 'ssh private-1' (y así sucesivamente)"