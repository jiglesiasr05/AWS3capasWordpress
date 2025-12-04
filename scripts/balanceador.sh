#!/bin/bash
# Script Balanceador: Configura Apache Proxy Balancer y HTTPS con CertBot.

# VARIABLES CRÍTICAS
DOMAIN_NAME="jaimeiglesias.ddns.net"
ADMIN_EMAIL="contacto@jaimeiglesias.es"
WS1_IP="10.0.2.20"
WS2_IP="10.0.2.21"

#Configuración de Hostname
sudo hostnamectl set-hostname BalanceadorJaimeIglesias
echo "Hostname configurado"
sudo apt update
# Instalación desatendida de Apache y módulos SSL/CertBot
sudo DEBIAN_FRONTEND=noninteractive apt install apache2 python3-certbot-apache -y
echo "Instalacion de parquetes realizado"
# Habilitar módulos necesarios
sudo a2enmod proxy proxy_balancer proxy_http rewrite headers ssl lbmethod_byrequests
echo "Modulos apache necesarios habilitados"
#Configuración Temporal de HTTP (para la validación de CertBot)
TEMP_VHOST_CONF="/etc/apache2/sites-available/000-default.conf"

sudo cat <<EOT > $TEMP_VHOST_CONF
<VirtualHost *:80>
    ServerAdmin $ADMIN_EMAIL
    ServerName $DOMAIN_NAME

    # Definición del Cluster (Grupo de Servidores Web)
    <Proxy balancer://wordpresscluster>
        BalancerMember http://$WS1_IP:80 route=ws1
        BalancerMember http://$WS2_IP:80 route=ws2
        ProxySet stickysession=JSESSIONID|sessionid lbmethod=byrequests
    </Proxy>

    ProxyPass / balancer://wordpresscluster/
    ProxyPassReverse / balancer://wordpresscluster/

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOT
echo "archivo 000-default.conf configurado para aplicar CertBot"
sudo systemctl restart apache2
# Obtención y Configuración HTTPS con CertBot
# Ejecución no interactiva de CertBot. Si el DNS falla, este paso será el único que falle.
sudo certbot --apache -d $DOMAIN_NAME --non-interactive --agree-tos -m $ADMIN_EMAIL --redirect --hsts --uir
echo "Certificado expedido..."
#Reinicio Final del Balanceador
sudo systemctl restart apache2
echo "Balanceador configurado con HTTPS y Balanceo de Carga."
