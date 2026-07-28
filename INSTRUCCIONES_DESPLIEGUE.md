# Instrucciones de Despliegue en VPS Real

Como tu profesor ha solicitado que el proyecto esté en un **VPS Real (accesible a internet mediante una URL pública y sin requerir ejecutar archivos localmente)**, aquí tienes exactamente lo que necesitas hacer.

Tu proyecto está hecho en Python (Flask) usando MySQL. El profesor pidió que sea un "Proyecto Apache". Hemos creado un script automatizado que instala y configura Apache como proxy inverso para tu aplicación Python en un VPS con Ubuntu.

## Paso 1: Conseguir un VPS Real
Debes crear una cuenta y adquirir un VPS (Virtual Private Server) en la nube. Te recomiendo estas opciones gratuitas o muy baratas:

*   **AWS (Amazon Web Services):** Tienen una capa gratuita por 1 año. Puedes crear una instancia "EC2" con Ubuntu 22.04 o 24.04.
*   **DigitalOcean / Vultr / Linode:** Cuestan alrededor de $4 o $5 dólares al mes. (Suelen regalar saldo a estudiantes con GitHub Student Developer Pack).
*   **Google Cloud:** Ofrece una instancia "e2-micro" gratis de por vida.

**Importante:** Asegúrate de elegir el sistema operativo **Ubuntu 22.04 LTS o Ubuntu 24.04 LTS**.
Asegúrate de configurar los **Grupos de Seguridad / Firewall** del VPS para permitir tráfico en el puerto `80` (HTTP) y `22` (SSH).

## Paso 2: Subir tu código al VPS
Una vez que tengas tu VPS en la nube, te darán una **IP Pública** y un usuario (usualmente `ubuntu` o `root`).
Puedes usar un programa como **FileZilla** o **WinSCP** (desde tu Windows) para conectarte al servidor y subir toda la carpeta de tu proyecto (este código que estamos viendo) directamente al servidor.
Otra opción profesional es subir tu código a GitHub y usar `git clone` dentro del servidor.

## Paso 3: Ejecutar el Script de Despliegue Automatizado
Hemos creado el archivo `scripts/deploy_vps_ubuntu.sh` que hace todo el trabajo pesado.
Una vez que tu código esté en el servidor, conéctate a él (mediante SSH, usando herramientas como PuTTY o desde tu terminal de Windows: `ssh ubuntu@IP_DEL_VPS`).

Dirígete a la carpeta donde subiste los archivos y ejecuta estos dos comandos:

```bash
# Dale permisos de ejecución al script
chmod +x scripts/deploy_vps_ubuntu.sh

# Ejecútalo con privilegios de administrador
sudo ./scripts/deploy_vps_ubuntu.sh
```

## Paso 4: ¡Mostrar el resultado!
El script instalará Apache, MySQL, y Python. Configurará la base de datos automáticamente con tu archivo `init_db.sql`, instalará las dependencias en un entorno virtual, creará el servicio en segundo plano (Gunicorn) y configurará **Apache** para que enrute las peticiones.

Al finalizar, simplemente dale al profesor tu URL:
`http://<IP_PUBLICA_DE_TU_VPS>/`

Cualquier persona en cualquier computadora podrá abrir esa dirección y verá la aplicación funcionando las 24 horas del día.
