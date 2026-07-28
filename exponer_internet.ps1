# Script para levantar el proyecto localmente y exponerlo a internet usando Cloudflare Tunnels (Sin registro)

$ErrorActionPreference = "Stop"
$ProjectPath = $PSScriptRoot

Write-Host "=========================================="
Write-Host "Iniciando Gestor de Actividades y Túnel..."
Write-Host "=========================================="

# 1. Comprobar que Python está instalado
if (-not (Get-Command "py" -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: No tienes Python instalado. Por favor instálalo." -ForegroundColor Red
    exit 1
}

# 2. Configurar el Entorno de Python
Write-Host "-> Configurando entorno virtual e instalando dependencias..."
if (-not (Test-Path "$ProjectPath\venv")) {
    py -m venv "$ProjectPath\venv"
}

# Activar venv y usarlo para instalar/correr
$PythonExe = "$ProjectPath\venv\Scripts\python.exe"
$PipExe = "$ProjectPath\venv\Scripts\pip.exe"

& $PipExe install -r "$ProjectPath\requirements.txt" | Out-Null

# Asegurar que exista un .env
if (-not (Test-Path "$ProjectPath\.env")) {
    Copy-Item "$ProjectPath\.env.example" "$ProjectPath\.env"
}

# 3. Descargar Cloudflared (Herramienta para el túnel sin registro) si no existe
$CloudflaredExe = "$ProjectPath\cloudflared.exe"
if (-not (Test-Path $CloudflaredExe)) {
    Write-Host "-> Descargando Cloudflared (herramienta de túnel seguro)..."
    Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile $CloudflaredExe
}

# 4. Iniciar Flask en segundo plano
Write-Host "-> Iniciando tu aplicación Flask en el puerto 5000..."
# Matamos procesos previos de Python por si acaso
Stop-Process -Name "python" -Force -ErrorAction SilentlyContinue

$FlaskProcess = Start-Process -FilePath $PythonExe -ArgumentList "app.py" -WorkingDirectory $ProjectPath -PassThru
Start-Sleep -Seconds 3

# 5. Iniciar Túnel
Write-Host "-> Creando URL pública de internet..."
Write-Host "=========================================="
Write-Host "¡IMPORTANTE! Copia la URL que termina en .trycloudflare.com" -ForegroundColor Green
Write-Host "Esa es la URL que le darás al ingeniero." -ForegroundColor Green
Write-Host "=========================================="
Write-Host "NO CIERRES ESTA VENTANA MIENTRAS EL INGENIERO ESTÉ REVISANDO." -ForegroundColor Yellow

& $CloudflaredExe tunnel --url http://127.0.0.1:5000

# Cuando se cierra cloudflared, detenemos Flask
Stop-Process -Id $FlaskProcess.Id -Force
Write-Host "Servidor detenido."
