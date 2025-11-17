#!/usr/bin/env bash
set -euo pipefail

# Script interactivo para listar y limpiar imágenes/volúmenes/dangling resources de Docker
# NO borra automáticamente sin confirmación del usuario.

echo "Listando contenedores actuales..."
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'

echo "\nImágenes huérfanas (dangling):"
docker images -f dangling=true

echo "\nVolúmenes huérfanos (dangling):"
docker volume ls -f dangling=true

read -p "¿Deseas eliminar imágenes huérfanas (dangling) ahora? [y/N]: " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  echo "Eliminando imágenes dangling..."
  docker image prune -f
fi

read -p "¿Deseas eliminar volúmenes dangling ahora? [y/N]: " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  echo "Eliminando volúmenes dangling..."
  docker volume prune -f
fi

# También listar imágenes no usadas por contenedores en ejecución
echo "\nImágenes no referenciadas por contenedores en ejecución (posible candidata a limpieza) (no eliminadas automáticamente):"
# Listar images no referenciadas por un contenedor
CONTAINER_IMAGES=$(docker ps --format '{{.Image}}' | sort -u)
ALL_IMAGES=$(docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | awk '{print $1}')

for img in $ALL_IMAGES; do
  if ! echo "$CONTAINER_IMAGES" | grep -q "^$img$"; then
    echo "  $img"
  fi
done

read -p "¿Deseas eliminar imágenes sin contenedores (NO las imágenes en ejecución)? Escribe yes para confirmar: " confirm
if [[ "$confirm" == "yes" ]]; then
  echo "Eliminando imágenes no referenciadas por contenedores en ejecución (esto eliminará IMÁGENES locales, no contendores)."
  # Esto eliminará las imágenes que no estén siendo usadas por contenedores
  docker image prune -a
fi

# Opción para limpiar contenedores detenidos
read -p "¿Deseas eliminar contenedores detenidos? [y/N]: " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  docker container prune -f
fi

echo "Limpieza final completada. Revisa los contenedores con 'docker ps' y las imágenes con 'docker images'."
