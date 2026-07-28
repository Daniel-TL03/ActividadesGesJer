#!/bin/bash
# Script de despliegue automático para el Proyecto Apache (Gestor de Actividades)
# SO Requerido: Ubuntu 22.04 LTS o Ubuntu 24.04 LTS en un VPS REAL
# Se debe ejecutar como usuario root o con sudo.

echo "=========================================="
echo "Iniciando configuración del VPS real..."
echo "=========================================="

# 1. Actualizar sistema e instalar dependencias
echo "1. Actualizando paquetes del sistema e instalando dependencias..."
apt update && apt upgrade -y
apt install -y apache2 mysql-server python3 python3-pip python3-venv git

# 2. Configurar Base de Datos
echo "2. Configurando base de datos..."
# Crear base de datos y usuario según init_db.sql
mysql -u root -e "CREATE DATABASE IF NOT EXISTS gestor_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -e "CREATE USER IF NOT EXISTS 'gestor_user'@'localhost' IDENTIFIED BY 'CambiameYa2024!';"
mysql -u root -e "GRANT SELECT, INSERT, UPDATE, DELETE ON gestor_db.* TO 'gestor_user'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Si el archivo init_db.sql existe en la carpeta actual, cargar los datos
if [ -f "init_db.sql" ]; then
    mysql -u root < init_db.sql
    echo "Tablas inicializadas con init_db.sql"
fi

# 3. Mover la aplicación al directorio del servidor web
echo "3. Preparando el directorio de la aplicación..."
APP_DIR="/var/www/gestor-actividades"
mkdir -p $APP_DIR
# Copiar todos los archivos de la carpeta actual al directorio de la aplicación
cp -r ./* $APP_DIR/
chown -R www-data:www-data $APP_DIR

# 4. Configurar el entorno de Python
echo "4. Instalando dependencias de Python..."
cd $APP_DIR
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Crear archivo .env usando el ejemplo
if [ ! -f ".env" ]; then
    cp .env.example .env
fi

# 5. Configurar el servicio Gunicorn para mantener la app viva
echo "5. Creando el servicio systemd para Gunicorn..."
cat > /etc/systemd/system/gestor-actividades.service <<EOF
[Unit]
Description=Gunicorn instance to serve Gestor Actividades
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/gestor-actividades
Environment="PATH=/var/www/gestor-actividades/venv/bin"
ExecStart=/var/www/gestor-actividades/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:5000 app:app

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start gestor-actividades
systemctl enable gestor-actividades

# 6. Configurar Apache como Proxy Inverso
echo "6. Configurando Apache para servir la app en el puerto 80..."
a2enmod proxy
a2enmod proxy_http

cat > /etc/apache2/sites-available/gestor-actividades.conf <<EOF
<VirtualHost *:80>
    ServerName localhost

    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:5000/
    ProxyPassReverse / http://127.0.0.1:5000/

    ErrorLog \${APACHE_LOG_DIR}/gestor-actividades-error.log
    CustomLog \${APACHE_LOG_DIR}/gestor-actividades-access.log combined
</VirtualHost>
EOF

a2dissite 000-default.conf
a2ensite gestor-actividades.conf
systemctl restart apache2

echo "=========================================="
echo "¡DESPLIEGUE COMPLETADO!"
echo "Tu aplicación está ahora en línea en este VPS."
echo "Ingresa la IP Pública de este servidor en tu navegador (ej: http://TU_IP_PUBLICA)."
echo "=========================================="
