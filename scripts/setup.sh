#!/usr/bin/env bash
# setup.sh — Provisionamiento completo del VPS (Ubuntu 22.04/24.04)
# Instala Apache, MySQL, Python y configura todo.
# Ejecutar UNA vez como root:  chmod +x setup.sh && sudo ./setup.sh

set -euo pipefail

APP_DIR="/var/www/gestor-actividades"
APP_USER="deploy"

echo "=== 1/8  Actualizando sistema ==="
apt update && apt upgrade -y

echo "=== 2/8  Dependencias base ==="
apt install -y curl git ufw fail2ban rsync unattended-upgrades

echo "=== 3/8  Usuario de despliegue ==="
id -u "$APP_USER" &>/dev/null || adduser --disabled-password --gecos "" "$APP_USER"
usermod -aG sudo "$APP_USER"
mkdir -p /home/$APP_USER/.ssh
chmod 700 /home/$APP_USER/.ssh
touch /home/$APP_USER/.ssh/authorized_keys
chmod 600 /home/$APP_USER/.ssh/authorized_keys
chown -R $APP_USER:$APP_USER /home/$APP_USER/.ssh
echo "    → Agregá la clave pública de GitHub Actions en /home/$APP_USER/.ssh/authorized_keys"

echo "=== 4/8  Instalando Python ==="
apt install -y python3 python3-venv python3-pip

echo "=== 5/8  Instalando MySQL ==="
apt install -y mysql-server
systemctl enable mysql && systemctl start mysql
# Crear BD y usuario
mysql -e "CREATE DATABASE IF NOT EXISTS gestor_db CHARACTER SET utf8mb4;"
mysql -e "CREATE USER IF NOT EXISTS 'gestor_user'@'localhost' IDENTIFIED BY 'CambiameYa2024!';"
mysql -e "GRANT ALL ON gestor_db.* TO 'gestor_user'@'localhost'; FLUSH PRIVILEGES;"
echo "    → Cargá el esquema: mysql -u gestor_user -p gestor_db < init_db.sql"

echo "=== 6/8  Instalando Apache ==="
apt install -y apache2
a2enmod proxy proxy_http headers deflate rewrite
cp apache.conf /etc/apache2/sites-available/gestor-actividades.conf
a2ensite gestor-actividades.conf
a2dissite 000-default.conf
apache2ctl configtest && systemctl reload apache2

echo "=== 7/8  Firewall ==="
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw limit 22/tcp
ufw --force enable
systemctl enable fail2ban && systemctl restart fail2ban

echo "=== 8/8  Preparando directorio de la app ==="
mkdir -p "$APP_DIR"
chown -R $APP_USER:$APP_USER "$APP_DIR"
sudo -u $APP_USER python3 -m venv "$APP_DIR/venv"

# Instalar servicio systemd
cp app.service /etc/systemd/system/gestor-actividades.service
systemctl daemon-reload
systemctl enable gestor-actividades

dpkg-reconfigure -f noninteractive unattended-upgrades

echo ""
echo "✅ Provisionamiento completo."
echo "   1) Configurar .env en $APP_DIR/"
echo "   2) Cargar esquema: mysql -u gestor_user -p gestor_db < init_db.sql"
echo "   3) Agregar clave SSH del runner de GitHub Actions"
