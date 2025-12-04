#!/bin/bash
# Indicar el nuevo nombre del host
echo "Empezando provisionamiento"
echo "Configuracion del hostname"
sudo hostnamectl set-hostname NFSJaimeIglesias
# Instalación de NFS
sudo apt update
sudo apt install nfs-kernel-server -y
echo "Instalando paquetes necesarios"


# Descargar y descomprimir WordPress
sudo mkdir -p /var/www/html
cd /var/www/html
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xzf latest.tar.gz
sudo mv wordpress/* .
sudo rm -r wordpress
sudo rm -f latest.tar.gz
echo "WordPress esta disponible"
# Configurar permisos para WordPress
sudo chown -R www-data:www-data /var/www/html

#configurar NFS para compartir el directorio /var/www/html
echo "/var/www/html    10.0.3.20(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
echo "/var/www/html    10.0.3.21(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
echo "NFS se ha configurado para compartir el directorio /var/www/html."

