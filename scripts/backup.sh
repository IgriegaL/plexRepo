#!/bin/bash
# Script de backup antes de actualizar
# Uso: ./scripts/backup.sh

set -e

echo "💾 Creando backup del sistema..."
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directorio de backups
BACKUP_DIR="$HOME/plex-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="plex-backup-${TIMESTAMP}"

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

echo "📁 Directorio de backup: $BACKUP_DIR/$BACKUP_NAME"
echo ""

# 1. Backup de archivos de configuración del proyecto
echo "1️⃣  Respaldando archivos de configuración..."
mkdir -p "$BACKUP_DIR/$BACKUP_NAME/config"
cp docker-compose.yml "$BACKUP_DIR/$BACKUP_NAME/config/" 2>/dev/null || true
cp .env "$BACKUP_DIR/$BACKUP_NAME/config/" 2>/dev/null || true
cp prometheus.yml "$BACKUP_DIR/$BACKUP_NAME/config/" 2>/dev/null || true
cp -r grafana "$BACKUP_DIR/$BACKUP_NAME/config/" 2>/dev/null || true
echo -e "${GREEN}✅ Archivos de configuración respaldados${NC}"
echo ""

# 2. Backup de volúmenes de Docker (solo configs, no medios)
echo "2️⃣  Respaldando volúmenes de configuración..."

# Leer rutas del .env
if [ -f .env ]; then
    source .env
    
    # Backup de configuraciones (excluyendo medios grandes)
    CONFIG_VOLUMES=(
        "$PLEX_CONFIG_VOLUME"
        "$SONARR_CONFIG_VOLUME"
        "$RADARR_CONFIG_VOLUME"
        "$BAZARR_CONFIG_VOLUME"
        "$PROWLARR_CONFIG_VOLUME"
        "$OVERSEERR_CONFIG_VOLUME"
        "$QBITTORRENT_CONFIG_VOLUME"
    )
    
    for volume in "${CONFIG_VOLUMES[@]}"; do
        if [ -d "$volume" ]; then
            volume_name=$(basename "$volume")
            echo "   Respaldando $volume_name..."
            
            # Crear tar.gz del volumen
            sudo tar -czf "$BACKUP_DIR/$BACKUP_NAME/${volume_name}.tar.gz" \
                -C "$(dirname "$volume")" \
                "$(basename "$volume")" 2>/dev/null || {
                echo -e "${YELLOW}⚠️  No se pudo respaldar $volume_name (puede requerir permisos)${NC}"
            }
        fi
    done
    
    echo -e "${GREEN}✅ Volúmenes respaldados${NC}"
else
    echo -e "${YELLOW}⚠️  Archivo .env no encontrado, saltando backup de volúmenes${NC}"
fi
echo ""

# 3. Backup de base de datos de Plex (crítico)
echo "3️⃣  Respaldando base de datos de Plex..."
if [ -d "$PLEX_CONFIG_VOLUME/Library/Application Support/Plex Media Server/Plug-in Support/Databases/" ]; then
    sudo tar -czf "$BACKUP_DIR/$BACKUP_NAME/plex-databases.tar.gz" \
        -C "$PLEX_CONFIG_VOLUME/Library/Application Support/Plex Media Server/Plug-in Support" \
        "Databases" 2>/dev/null || {
        echo -e "${YELLOW}⚠️  No se pudo respaldar base de datos de Plex${NC}"
    }
    echo -e "${GREEN}✅ Base de datos de Plex respaldada${NC}"
else
    echo -e "${YELLOW}⚠️  Base de datos de Plex no encontrada${NC}"
fi
echo ""

# 4. Guardar estado actual de contenedores
echo "4️⃣  Guardando estado de contenedores..."
docker-compose ps > "$BACKUP_DIR/$BACKUP_NAME/containers-state.txt" 2>/dev/null || true
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" > "$BACKUP_DIR/$BACKUP_NAME/docker-ps.txt" 2>/dev/null || true
echo -e "${GREEN}✅ Estado guardado${NC}"
echo ""

# 5. Crear archivo de información
echo "5️⃣  Creando archivo de información..."
cat > "$BACKUP_DIR/$BACKUP_NAME/backup-info.txt" << EOF
Backup creado: $(date)
Hostname: $(hostname)
Usuario: $(whoami)
Directorio: $(pwd)

Versiones:
- Docker: $(docker --version)
- Docker Compose: $(docker-compose --version)

Contenido del backup:
- Archivos de configuración del proyecto
- Volúmenes de configuración de servicios
- Base de datos de Plex
- Estado de contenedores

Para restaurar:
1. Detener servicios: docker-compose down
2. Restaurar configs: cp -r config/* /ruta/proyecto/
3. Restaurar volúmenes: tar -xzf <volumen>.tar.gz -C /destino/
4. Reiniciar: docker-compose up -d
EOF
echo -e "${GREEN}✅ Información guardada${NC}"
echo ""

# Calcular tamaño del backup
BACKUP_SIZE=$(du -sh "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)

# Resumen
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Backup completado exitosamente${NC}"
echo ""
echo "📊 Información del backup:"
echo "   Ubicación: $BACKUP_DIR/$BACKUP_NAME"
echo "   Tamaño: $BACKUP_SIZE"
echo "   Timestamp: $TIMESTAMP"
echo ""
echo "📝 Para restaurar este backup:"
echo "   ./scripts/restore.sh $BACKUP_NAME"
echo ""
echo "⚠️  IMPORTANTE: Los archivos de medios (películas/series) NO están"
echo "   incluidos en el backup por su gran tamaño."
