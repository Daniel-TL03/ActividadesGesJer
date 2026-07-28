-- init_db.sql
-- Esquema MySQL para el Gestor de Actividades
-- Ejecutar: mysql -u root -p < init_db.sql

CREATE DATABASE IF NOT EXISTS gestor_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE gestor_db;

CREATE TABLE IF NOT EXISTS tareas (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    titulo      VARCHAR(255) NOT NULL,
    descripcion TEXT NULL,
    completada  TINYINT(1) NOT NULL DEFAULT 0,
    creado      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Usuario de la aplicación
CREATE USER IF NOT EXISTS 'gestor_user'@'localhost' IDENTIFIED BY 'CambiameYa2024!';
GRANT SELECT, INSERT, UPDATE, DELETE ON gestor_db.* TO 'gestor_user'@'localhost';
FLUSH PRIVILEGES;

-- Datos de ejemplo
INSERT IGNORE INTO tareas (id, titulo, descripcion, completada) VALUES
  (1, 'Configurar el VPS',          'Provisionar Ubuntu y actualizar paquetes',        1),
  (2, 'Instalar Apache y MySQL',    'Configurar el stack LAMP para la aplicación',     0),
  (3, 'Automatizar con CI/CD',      'Pipeline de GitHub Actions con SSH y rsync',      0);
