#!/bin/bash

# ===========================
# VARIABLES
# ===========================
REPO_DIR="/home/ubuntu/DAW-Tarea"
TOMCAT_DIR="/opt/tomcat"
SRC_DIR="$REPO_DIR/src"
BUILD_DIR="$REPO_DIR/build"
WAR_NAME="hola.war"
SERVLET_PACKAGE="hola"
SERVICE_NAME="tomcat10"

echo "==================================="
echo "   DESPLIEGUE AUTOMATIZADO INICIADO"
echo "==================================="

# ===========================
# ACTUALIZAR CÓDIGO
# ===========================
echo "🔄 Actualizando código desde Git..."
cd "$REPO_DIR" || { echo " No se encontró el repositorio"; exit 1; }
git pull origin main || { echo " Error al hacer git pull"; exit 1; }

# ===========================
# LIMPIAR COMPILACIÓN ANTERIOR
# ===========================
echo "🧹 Limpiando build anterior..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/WEB-INF/classes"

# ===========================
# COMPILAR SERVLET
# ===========================
echo " Compilando aplicación..."
javac -cp "$TOMCAT_DIR/lib/servlet-api.jar" \
      -d "$BUILD_DIR/WEB-INF/classes" \
      "$SRC_DIR/$SERVLET_PACKAGE"/*.java

if [ $? -ne 0 ]; then
    echo " Error en compilación"
    exit 1
fi

# ===========================
# GENERAR WAR
# ===========================
echo "📦 Generando archivo WAR..."
cd "$BUILD_DIR" || exit 1
jar -cvf "$WAR_NAME" . > /dev/null

if [ $? -ne 0 ]; then
    echo " Error generando WAR"
    exit 1
fi

# ===========================
# DESPLEGAR EN TOMCAT
# ===========================
echo " Desplegando en Tomcat..."
sudo rm -rf "$TOMCAT_DIR/webapps/hola"
sudo rm -f "$TOMCAT_DIR/webapps/$WAR_NAME"
sudo cp "$WAR_NAME" "$TOMCAT_DIR/webapps/"

if [ $? -ne 0 ]; then
    echo " Error copiando WAR"
    exit 1
fi

# ===========================
# REINICIAR TOMCAT
# ===========================
echo "🔁 Reiniciando servicio..."
sudo systemctl restart $SERVICE_NAME

if [ $? -ne 0 ]; then
    echo " Error reiniciando Tomcat"
    exit 1
fi

echo "⏳ Esperando arranque..."
sleep 8

# ===========================
# VERIFICACIÓN
# ===========================
echo "🔍 Verificando despliegue..."
curl -I http://localhost:8080/hola/hola

if [ $? -ne 0 ]; then
    echo " La aplicación no responde"
    exit 1
fi

echo "==================================="
echo "   ✅ DESPLIEGUE COMPLETADO"
echo "==================================="

