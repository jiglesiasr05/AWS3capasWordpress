# INFRAESTRUCTURA WORDPRESS EN 3 CAPAS ALOJADO EN AWS
## TABLA DE CONTENIDOS
1. [ESQUEMA DE RED](#esquema-de-red)
2. [DIRECCIONAMIENTO IP](#direccionamiento-ip)
3. [REGLAS FIREWALL(GRUPOS DE SEGURIDAD)](#reglas-firewall)
4. [SCRIPTS DE IMPLEMENTACIÓN](#scripts-de-implementacion)
5. [INSTRUCCIONES DE USO](#instrucciones)


## ESQUEMA DE RED

[EsquemaRed](img/EsquemaredASCII.png)

## INFRAESTRUCTURA
Se ha creado una VPC en la red de AWS con IP 10.0.0.0/16 para seguidamente crear las subredes.



| Capa | Tipo de Subred | IP Red | Función |
| :---: | :---: | :---: | :--- |
| **1** | Pública | 10.0.1.0/24 | Recibe las peticiones en el balanceador |
| **2** | Privada | 10.0.2.0/24 | Servidores Web que alojan Wordpress |
| **3** | Privada | 10.0.3.0/24 | Capa de datos (NFS y BBDD) |


Con esta infraestructura estamos protegiendo los datos importantes como son los datos de la base de datos o demás archivos que debamos compartir en el NFS, aparte de los de WordPress.
- Se comprende un balanceador situado en la __CAPA 1__ para las cargas de los webs servers WS1 y WS2.
- La instalación de WordPress se encuentra en cada uno de los Webservers en __CAPA 2__ y comparten los datos en NFS y guardan datos en la base de datos en __CAPA 3__ para tener una integridad en los datos.
- Se distinguen dos tipos de enrutamiento:
 
  - Enrutamiento con puerta de enlace.
     Esta tiene un acceso a la red de internet para recibir peticiones web y una ruta al VPC 10.0.0.0/16
  - Enrutamiento sin puerta de enlace.
     Esta no tiene una puerta de enlace, por lo que solo permite peticiones de la misma red interna.
---
## DIRECCIONAMIENTO IP



| Capa | Máquina | IP Privada | Subred | Función |
|------|-----------|-----------|--------|---------|
| 1 | balanceador | 10.0.1.10 | 10.0.1.0/24 | Distribuye tráfico HTTP/HTTPS |
| 2 | WS1-JaimeIglesias | 10.0.2.20 | 10.0.2.0/24 | Aloja WordPress |
| 2 | WS2-JaimeIglesias | 10.0.2.21 | 10.0.2.0/24 | Aloja WordPress |
| 3 | NFS | 10.0.3.30 | 10.0.3.0/24 | Almacenamiento compartido |
| 3 | BBDD-JaimeIglesias | 10.0.3.40 | 10.0.3.0/24 | MySQL/MariaDB |


Para mejorar el aprendizaje de las IP's las máquinas mantienen su número de hosts cuando comparten redes.


---

## REGLAS FIREWALL (GRUPOS DE SEGURIDAD)<
La creación de las máquinas ha llevado a la necesidad de crear unos grupos de seguridad para permitir y denegar los paquetes que no deseamos que lleguen.


**TODAS LAS MÁQUINAS TIENEN COMO REGLAS DE SALIDAS TODOS LOS PAQUETES A TODA LA RED**
### BALANCEADOR
#### CAPA 1 10.0.1.10/24


Esta máquina necesita la recepción únicamente de paquetes del protocolo **SSH** para la conexión remota y paquetes **HTTP** y **HTTPS**.


| Protocolo | Puerto | Origen | Descripción |
|-----------|--------|--------|-------------|
| TCP | 80 | 0.0.0.0/0 | HTTP desde Internet |
| TCP | 443 | 0.0.0.0/0 | HTTPS desde Internet |
| TCP | 22 | 0.0.0.0/0 | SSH administración |




### WEBSERVERS
#### CAPA 2 10.0.2.20/24 Y 10.0.2.21/24


Los servidores web ya se encuentran en una subred privada sin puerta de enlace, lo cual implica que no tienen acceso a la red de internet. Todas las peticiones de entrada deben ser de origen dentro de las redes en las que se encuentran


Estas reglas permiten el acceso desde el balanceador a los servicios web vía **HTTP** o **HTTPS**, acceso a paquetes provenientes del servidor **NFS**, conexión **SSH** solo desde el balanceador y conexiones **SQL** solo desde el servidor de bases de datos


| Protocolo | Puerto | Origen | Descripción |
|-----------|--------|--------|-------------|
| TCP | 80 | 10.0.1.10 | HTTP desde Balanceador |
| TCP | 443 | 10.0.1.10 | HTTPS desde Balanceador |
| TCP | 2049 | 10.0.3.30 | NFS desde NFS |
| TCP | 22 | [10.0.2.10 | SSH administración |
| TCP | 3306 | 10.0.3.40 | MySQL desde BD |




### NFS
#### CAPA 3 10.0.3.30/24


El servidor NFS debe únicamente recibir peticiones de paquetes **NFS** desde los webs servers de la capa 2.
Se aplican reglas para la conexión **SSH** solo desde capa 2


| Protocolo | Puerto | Origen | Descripción |
|-----------|--------|--------|-------------|
| TCP | 2049 | 10.0.3.0/24 | NFS desde WebServers |
| TCP | 22 | [10.0.3.0/24 | SSH administración |




### BASE DE DATOS
#### CAPA 3 10.0.3.40/24


Este es el eslabón más débil donde se encuentra la información más importante, lo cual hay que prestar atención en las reglas que se le asignan.
Para este grupo únicamente se asignan reglas de entrada de peticiones **SQL** y **SSH** para su administración.


| Protocolo | Puerto | Origen | Descripción |
|-----------|--------|--------|-------------|
| TCP | 3306 | 10.0.3.0/24 | MySQL desde WebServers |
| TCP | 22 | 10.0.3.0/24| SSH administración |


### RECORDATORIO
Como se puede observar, las conexiones **SSH** solo se pueden establecer desde la capa anterior y más expuesta.




---


##  CREACIÓN DE MÁQUINAS


Todas las máquinas creadas son instaladas con _Ubuntu_  y es **importante habilitar la asignación de IP pública** para obtener una conexión a la red de internet en las máquinas asignadas a subredes privadas para su aprovisionamiento y desactivar esta opción tras acabar el proceso de instalación.


En esta implantación se empezará a instalar las máquinas desde la __CAPA 3__  para facilitar la administración con las IP públicas y evitar exponer el servicio sin que funciones correctamente.




### BASE DE DATOS (CAPA 3)


Esta maquina tiene tan solo una interfaz de red que está en la __CAPA 3__ de esta infraestructura.


Se debe crear la máquina asignando la VPC creada y la subred asociada a la tabla de enrutamiento privada en capa 3.  (10.0.3.0/24).


Esta instancia se configura con la IP principal 10.0.3.40/24.


Se debe designar uno de los grupos de seguridad creados con las reglas de permiso de entrada de paquetes TCP por el puerto 3306.


_Este caso es el que debemos habilitar una IP pública para después deshabilitarla porque la subred no tiene una puerta de enlace asociada._


Se deben especificar en la pestaña de _Detalles Avanzados_  al final en _User Data_ el contenido de [Script Base de Datos](scripts/BasedeDatos.sh).






#### Se debe prestar atención especial en la ejecución de estos comandos


Este código realiza la creación de un usuario remoto para realizar la consulta con todos los permisos para evitar errores, ya que las acciones de WordPress requieren la mayoría de permisos que se pueden asignar, y la creación de la base de datos que va a ser usada.
```
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
```


Terminada las comprobaciones de que todo se haya ejecutado correctamente y se hayan instalado los paquetes necesarios, es necesario desactiva la opción de __Asignar una IP pública__.




### NFS  (CAPA 3)


La instancia NFS al igual que la base de datos, este servicio solo cuenta con una sola interfaz de red con conexión a la __CAPA 3__ .


Las configuraciones de red deben ser la conexión al VPC creado para esta infraestructura y asignarle la subred asignada a la capa 3 con la IP 10.0.3.30/24, al igual que la base de datos se debe habilitar la asignación de una IP pública para el aprovisionamiento y la instalación de paquetes necesarios.


El grupo de seguridad de esta instancia está creado con las reglas de entrada que permiten el acceso de paquetes TCP por el puerto 2049 que es el asignado al servicio DNS y la conexión SSH


En _Detalles Avanzados_ en el apartado de _User Data_ se debe añadir el código contenido en [Script NFS](scripts/NFS.sh).


Esta maquina contiene la instalación del CMS compartido en la carpeta _/var/www/html_ a los servidores web, de manera que permite una escalabilidad mucho más fácil.


Se debe prestar atención a la ejecución de estos comandos para evitar los fallos más comunes.
```
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
sudo chown -R www-data:www-data /var/www/html  #IMPORTANTE REVISAR EJECUCION


#configurar NFS para compartir el directorio /var/www/html
echo "/var/www/html    10.0.3.20(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
echo "/var/www/html    10.0.3.21(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
echo "NFS se ha configurado para compartir el directorio /var/www/html."


```


A igual que todas las maquinas con tabla de enrutamiento privada, recordar __deshabilitar la Asignación IP Pública tras el aprovisionamiento__.


### WEB SERVERS (CAPA 2)


Los webs servers se aprovisionan de la misma manera, estos van con la dos interfaces de red que configurar.


- Interfaz en __CAPA 2__
   - Estos llevan la subred asignada a la __CAPA 2__ (10.0.2.0/24)
       - WS1 10.0.2.20/24
       - WS2 10.0.2.21/24
- Interfaz en __CAPA 3__
   - Estos llevan la subred asignada a la __CAPA 3__ (10.0.3.0/24)
       - WS1 10.0.3.20/24
       - WS2 10.0.3.21/24
      
Donde se conectan con el NFS y la Base de Datos


Se debe de asignar el grupo de seguridad donde se permite la entrada de paquetes HTTPS y HTTP desde la capa 1 (10.0.1.10/24) y paquetes NFS y MySQL desde 10.0.3.30/24 y 10.0.3.40/24.


En _Detalles Avanzados_ en el apartado de _User Data_ se debe añadir el código contenido en [Script WebServers](scripts/webservers.sh).


_En esta instancia también se debe habilitar una IP pública para el aprovisionamiento_


En este script se instalan los servicios de servidores web y php y se monta el directorio compartido desde el NFS.


```
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
```


Esto permite que ya haya un servicio web donde ya tendriamos una web útil y gracias al NFS los datos serian compartidos entre los servidores.


### BALANCEADOR


El balanceador se encarga de recibir las peticiones web de la red de internet y balancear las cargas en este caso por número de peticiones recibidas. Ademas esta instancia contiene la IP publica de acceso a internet y los certificados SSL para el acceso por HTTPS.


Se necesita configurar dos interfaces de red.


- Interfaz en __CAPA 1__
   - Lleva la subred asignada a la __CAPA 1__ (10.0.1.0/24)
       - WS1 10.0.1.10/24
- Interfaz en __CAPA 2__
   - Lleva la subred asignada a la __CAPA 3__ (10.0.2.0/24)
       - WS1 10.0.2.10/24


El grupo de seguridad que debemos asignar permite el acceso desde HTTPS y HTTP desde cualquier red y SSH para la administracción.


En este caso la IP publica no es necesaria porque lleva asignada una subred con enrutamiento publico, es decir, tiene una puerta de enlace configurada.


Se debe prestar atención a el cambio en el archivo de configuracion de apache ```000-default.conf ``` con el siguiente script, donde se configura el clúster de servidores web a balancear.
[Scripts del Balanceador](/scripts/balanceador.sh).


```
Configuración Temporal de HTTP (para la validación de CertBot)
TEMP_VHOST_CONF="/etc/apache2/sites-available/000-default.conf"


sudo cat <<EOT > $TEMP_VHOST_CONF
<VirtualHost *:80>
   ServerAdmin $ADMIN_EMAIL
   ServerName $DOMAIN_NAME


   # Definición del Cluster (Grupo de Servidores Web)
   <Proxy balancer://wordpresscluster>
       BalancerMember http://$WS1_IP:80 route=ws1
       BalancerMember http://$WS2_IP:80 route=ws2
       ProxySet stickysession=JSESSIONID|sessionid lbmethod=byrequests  # METODO DE BALANCEO POR PETICIONES
   </Proxy>


   ProxyPass / balancer://wordpresscluster/
   ProxyPassReverse / balancer://wordpresscluster/


   ErrorLog \${APACHE_LOG_DIR}/error.log
   CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOT
echo "archivo 000-default.conf configurado para aplicar CertBot"
sudo systemctl restart apache2
```


Este script lleva implementado la expedición de un certificado SSL con ```certbot```, pero es posible que falle, ya que se debe tener un dominio asignado a una IP elástica de AWS y a su vez la asignación de esa IP a la interfaz de la capa 1 del balanceador. En caso de que no se ejecute por no cumplir los requisitos, debemos ejecutar el siguiente comando


```
sudo apt install python3-certbot-apache -y
sudo certbot --apache -d $DOMAIN_NAME --non-interactive --agree-tos -m $ADMIN_EMAIL --redirect --hsts --ir
```
Cambiando ```$DOMAIN_NAME``` por el nombre del dominio  y ```$ADMIN_EMAIL``` por un e-mail de contacto.
Esto creará automáticamente el archivo de apache que habilita la conexión HTTPS.




## INSTRUCCIONES DE USO
Para el acceso a esta infraestructura ya creada se debe acceder a través del nombre de dominio asignado a la IP elástica.


Para este caso se ha escogido el siguiente dominio.


[jaimeiglesias.ddns.net](https://jaimeiglesias.ddns.net)



Asegúrese de que las instancias en AWS están encendidas y accesibles.
