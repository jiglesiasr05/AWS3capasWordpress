#!/bin/bash
# Script DB: Instala MariaDB y crea la base de datos de WordPress.

# VARIABLES CRÍTICAS
DB_ROOT_PASS="wp_user"
DB_USER_PASS="wp_pass"
Configuración de Hostname e Instalación
echo "Configuracion del Hostaname"
sudo hostnamectl set-hostname DBJaimeIglesias
echo "Instalacion de paquetes"
sudo apt update
#DEBIAN_FRONTEND para una instalacion sin asistente
sudo DEBIAN_FRONTEND=noninteractive apt install mariadb-server -y


# Configuración Inicial y Creación de DB
echo "Creando usuario ..."
sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';"

# Crear la base de datos, el usuario y asignar permisos
sudo mysql -u root -p"${DB_ROOT_PASS}" -e "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
sudo mysql -u root -p"${DB_ROOT_PASS}" -e "CREATE USER 'wp_user'@'%' IDENTIFIED BY '${DB_USER_PASS}';"
#Todos los privilegios para evitar problemas
sudo mysql -u root -p"${DB_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_user'@'%';"
sudo mysql -u root -p"${DB_ROOT_PASS}" -e "FLUSH PRIVILEGES;"
echo "Base de datos y usuario creado exitosamente"
# Permitir Conexiones Externas (Capa 2)
sudo sed -i 's/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb
echo "Base de datos configurada."

