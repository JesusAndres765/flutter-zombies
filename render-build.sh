#!/usr/bin/env bash
# Salir inmediatamente si algún comando falla
set -e

echo "=== Iniciando la construcción de Flutter Web ==="

# 1. Clonar el SDK de Flutter directamente desde GitHub (canal estable)
if [ ! -d "flutter" ]; then
  echo "Clonando Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable
fi

# 2. Añadir Flutter a las variables de entorno (PATH) temporalmente para esta construcción
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Habilitar el soporte para web (por si acaso)
flutter config --enable-web

# 4. Obtener las dependencias de tu proyecto
echo "Descargando paquetes de pubspec..."
flutter pub get

# 5. Compilar la aplicación para web
echo "Compilando los archivos estáticos..."
flutter build web

echo "=== Construcción terminada con éxito ==="