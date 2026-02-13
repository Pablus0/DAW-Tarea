#!/bin/bash

# ===================================
# CONFIGURACIÓN
# ===================================

REPO_DIR="/home/ubuntu/DAW-Tarea"
WEBAPPS_DIR="/var/lib/tomcat10/webapps"
SRC_DIR="$REPO_DIR/src"
BUILD_DIR="$REPO_DIR/build"
WAR_NAME="hola.war"
APP_NAME="hola"
SERVLET_PACKAGE="hola"
SERVLET_CLASS="HolaServlet"
SERVICE_NAME="tomcat10"
SERVLET_URL="http://localhost:8080/$APP_NAME/hola"
SERVLET_JAR="/usr/share/java/tomcat10-servlet-api-10.1.16.jar"

echo "======================================="
echo "   DESPLIEGUE AUTOMATIZADO INICIADO"
echo "======================================="

# ===================================
# 1. ACTUALIZAR REPOSITORIO
# ===================================

echo " Actualizando repositorio..."
cd "$REPO_DIR" || exit 1
git pull origin main || exit 1

# ===================================
# 2. LIMPIAR BUILD ANTERIOR
# ===================================

echo " Limpiando compilaciones anteriores..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/WEB-INF/classes"

# ===================================
# 3. COMPILAR SERVLET
# ===================================

echo " Compilando código fuente..."
javac -cp "$SERVLET_JAR" \
      -d "$BUILD_DIR/WEB-INF/classes" \
      "$SRC_DIR/$SERVLET_PACKAGE"/*.java || exit 1

# ===================================
# 4. CREAR web.xml
# ===================================

echo " Generando web.xml..."
mkdir -p "$BUILD_DIR/WEB-INF"

cat > "$BUILD_DIR/WEB-INF/web.xml" <<EOF
<web-app xmlns="https://jakarta.ee/xml/ns/jakartaee"
         version="5.0">
  <servlet>
    <servlet-name>$SERVLET_CLASS</servlet-name>
    <servlet-class>$SERVLET_PACKAGE.$SERVLET_CLASS</servlet-class>
  </servlet>
  <servlet-mapping>
    <servlet-name>$SERVLET_CLASS</servlet-name>
    <url-pattern>/hola</url-pattern>
  </servlet-mapping>
</web-app>
EOF

# ===================================
# 5. GENERAR WAR
# ===================================

echo " Generando archivo WAR..."
cd "$BUILD_DIR" || exit 1
jar -cvf "$WAR_NAME" . > /dev/null || exit 1

# ===================================
# 6. ELIMINAR DESPLIEGUES ANTIGUOS
# ===================================

echo "🗑 Eliminando despliegues antiguos..."
sudo rm -rf "$WEBAPPS_DIR/$APP_NAME"
sudo rm -f "$WEBAPPS_DIR/$WAR_NAME"
sudo rm -f /var/lib/tomcat10/conf/Catalina/localhost/$APP_NAME.xml

# ===================================
# 7. COPIAR WAR Y AJUSTAR PERMISOS
# ===================================

echo " Copiando WAR a Tomcat y ajustando permisos..."
sudo cp "$WAR_NAME" "$WEBAPPS_DIR/"
sudo chown tomcat:tomcat "$WEBAPPS_DIR/$WAR_NAME"

# ===================================
# 8. CREAR CONTEXTO FIJO
# ===================================

echo " Creando archivo de contexto para Tomcat..."
echo "<Context docBase=\"$WEBAPPS_DIR/$WAR_NAME\" reloadable=\"true\"/>" | sudo tee /var/lib/tomcat10/conf/Catalina/localhost/$APP_NAME.xml

# ===================================
# 9. REINICIAR TOMCAT
# ===================================

echo "🔄 Reiniciando Tomcat..."
sudo systemctl restart "$SERVICE_NAME"

# ===================================
# 10. ESPERAR A QUE SE DESPLIEGUE EL WAR
# ===================================

echo "⏳ Esperando a que la aplicación se despliegue..."
TIMEOUT=40
while [ ! -d "$WEBAPPS_DIR/$APP_NAME/WEB-INF" ] && [ $TIMEOUT -gt 0 ]; do
    sleep 1
    TIMEOUT=$((TIMEOUT-1))
done

# ===================================
# 11. AJUSTAR PERMISOS DE LA CARPETA DESPLEGADA
# ===================================

sudo chown -R tomcat:tomcat "$WEBAPPS_DIR/$APP_NAME"

# ===================================
# 12. COMPROBAR DESPLIEGUE
# ===================================

echo " Comprobando aplicación..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SERVLET_URL")

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo " Aplicación desplegada correctamente."
else
    echo " Error en el despliegue. Código HTTP: $HTTP_STATUS"
    exit 1
fi

echo "======================================="
echo "   DESPLIEGUE FINALIZADO CON ÉXITO"
echo "======================================="


