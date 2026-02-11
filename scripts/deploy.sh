#!/bin/bash

# =========================================
# Despliegue automático de la aplicación Java en Tomcat
# =========================================

# Configuración de rutas
REPO_DIR="$HOME/DAW-Tarea"                     # Carpeta raíz del repositorio
SRC_DIR="$REPO_DIR/src"                        # Carpeta con el código fuente
BIN_DIR="$REPO_DIR/bin"                        # Carpeta donde se compilan los .class
WAR_NAME="HolaApp.war"                         # Nombre del archivo WAR
TOMCAT_WEBAPPS="/opt/tomcat/webapps"          # Carpeta webapps de Tomcat
SERVLET_API="/opt/tomcat/lib/servlet-api.jar" # Ruta del servlet-api.jar de Tomcat 10

# 1️⃣ Actualizar código desde GitHub
echo "=== Actualizando código desde GitHub ==="
cd "$REPO_DIR" || exit
git pull origin main

# 2️⃣ Limpiar compilaciones anteriores
echo "=== Limpiando compilaciones anteriores ==="
rm -rf "$BIN_DIR"
mkdir -p "$BIN_DIR"

# 3️⃣ Compilar código Java
echo "=== Compilando código Java ==="
javac -d "$BIN_DIR" -cp "$SERVLET_API" $(find "$SRC_DIR" -name "*.java")

# 4️⃣ Generar archivo WAR
echo "=== Generando archivo WAR ==="
cd "$BIN_DIR" || exit
jar -cvf "$WAR_NAME" *

# 5️⃣ Copiar WAR a Tomcat
echo "=== Copiando WAR a Tomcat ==="
sudo cp "$WAR_NAME" "$TOMCAT_WEBAPPS/"

# 6️⃣ Reiniciar Tomcat usando scripts de Tomcat (no systemctl)
echo "=== Reiniciando Tomcat ==="
sudo /opt/tomcat/bin/shutdown.sh
sudo /opt/tomcat/bin/startup.sh

# 7️⃣ Verificar que la aplicación responde
echo "=== Verificando despliegue ==="
sleep 5
APP_URL="http://localhost:8080/HolaApp/HolaServlet"
if curl -s --head "$APP_URL" | grep "200 OK" > /dev/null; then
    echo "✅ Despliegue correcto: la aplicación está funcionando en $APP_URL"
else
    echo "❌ Error: la aplicación no responde correctamente en $APP_URL"
fi

