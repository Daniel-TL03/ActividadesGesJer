#!/usr/bin/env bash
# backup.sh — Respaldo diario de MySQL
# Agregar a crontab:  0 3 * * * /var/www/gestor-actividades/scripts/backup.sh >> /var/log/gestor-backup.log 2>&1

set -euo pipefail

DB_NAME="gestor_db"
DB_USER="gestor_user"
DB_PASS="CambiameYa2024!"
DEST="/var/backups/gestor-actividades"
DAYS=14
STAMP=$(date +"%Y-%m-%d_%H%M%S")
FILE="$DEST/${DB_NAME}_${STAMP}.sql.gz"

mkdir -p "$DEST"
echo "[$(date)] Backup iniciando..."
mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$FILE"
echo "[$(date)] Creado: $FILE"

find "$DEST" -name "*.sql.gz" -mtime +"$DAYS" -delete
echo "[$(date)] Limpieza de backups antiguos completa."
