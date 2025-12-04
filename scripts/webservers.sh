#!/bin/bash
# Script WS: Instala PHP/Apache, configura la ruta estática y monta NFS.

sudo hostnamectl set-hostname JaimeIglesias
# Indicar el nuevo nombre del host
echo "127.0.1.1   JaimeIgleias" | sudo tee -a /etc/hosts
echo "Nombre del host cambiado a JaimeIglesias"


# Instalación de apache y php5
sudo apt update
sudo apt install apache2 -y
sudo apt install nfs-common -y
sudo apt install php php-mysql php-cli php-xml php-gd php-mbstring php-zip php-curl libapache2-mod-php -y
echo "Apcahe2 y NFS cliente se han instalado correctamente y están activos."


#Montaje NFS
sudo rm -rf /var/www/html/*
sudo mkdir -p /var/www/html
echo "10.0.3.30:/var/www/html /var/www/html nfs defaults 0 0" | sudo tee -a /etc/fstab
sudo chown -R www-data:www-data /var/www/html
sudo a2enmod ssl
sudo systemctl restart apache2
# Configurar Apache para servir WordPress
cd /etc/apache2/sites-available/
sudo cp  000-default.conf wordpress.conf
cat <<EOF | sudo tee /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
sudo a2ensite wordpress.conf
sudo a2dissite 000-default.conf
sudo systemctl restart apache2
echo "Apache configurado para servir WordPress desde /var/www/html."

