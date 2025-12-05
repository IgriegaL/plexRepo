#!/bin/bash
# Script de backup simple para configuraciones
# Uso: ./scripts/backup.sh

set -e

BACKUP_DIR="$HOME/plex-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TARGET_DIR="$BACKUP_DIR/backup-$TIMESTAMP"

echo "📦 Iniciando backup en $TARGET_DIR..."
mkdir -p "$TARGET_DIR"

# 1. Copiar archivos del proyecto
cp docker-compose.yml .env "$TARGET_DIR/"
echo "✅ Archivos de proyecto copiados."

# 2. Copiar configuraciones (si existen las variables en .env)
if [ -f .env ]; then
    source .env
    
    # Lista de volúmenes a respaldar
    VOLUMES=(
        "$PLEX_CONFIG_VOLUME"
        "$SONARR_CONFIG_VOLUME"
        "$RADARR_CONFIG_VOLUME"
        "$BAZARR_CONFIG_VOLUME"
        "$PROWLARR_CONFIG_VOLUME"
        "$OVERSEERR_CONFIG_VOLUME"
        "$QBITTORRENT_CONFIG_VOLUME"
        "$PORTAINER_CONFIG_VOLUME"
    )

    echo "📦 Respaldando volúmenes de configuración (esto puede tardar)..."
    for VOL in "${VOLUMES[@]}"; do
        if [ ! -z "$VOL" ] && [ -d "$VOL" ]; then
            NAME=$(basename "$VOL")
            echo "   - $NAME..."
            # Usar tar para preservar permisos
            tar -czf "$TARGET_DIR/$NAME.tar.gz" -C "$(dirname "$VOL")" "$NAME"
        fi
    done
fi

echo "🎉 Backup completado en: $TARGET_DIR"
