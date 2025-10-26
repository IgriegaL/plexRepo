#!/bin/bash
# Script de validación de configuración
# Uso: ./scripts/test-config.sh

set -e

echo "🔍 Validando configuración de Docker Compose..."
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contador de errores
ERRORS=0

# 1. Validar sintaxis YAML
echo "1️⃣  Validando sintaxis YAML..."
if docker-compose config > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Sintaxis YAML válida${NC}"
else
    echo -e "${RED}❌ Error en sintaxis YAML${NC}"
    docker-compose config
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 2. Verificar archivo .env existe
echo "2️⃣  Verificando archivo .env..."
if [ -f .env ]; then
    echo -e "${GREEN}✅ Archivo .env existe${NC}"
else
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    echo "   Copia .env.example a .env y configúralo"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 3. Verificar variables requeridas
echo "3️⃣  Verificando variables de entorno requeridas..."
REQUIRED_VARS=(
    "PUID"
    "PGID"
    "TZ"
    "PLEX_CLAIM"
    "GRAFANA_ADMIN_USER"
    "GRAFANA_ADMIN_PASSWORD"
    "PLEX_CONFIG_VOLUME"
    "TV_SERIES_VOLUME"
    "MOVIES_VOLUME"
    "DOWNLOADS_VOLUME"
)

for var in "${REQUIRED_VARS[@]}"; do
    if grep -q "^${var}=" .env 2>/dev/null; then
        value=$(grep "^${var}=" .env | cut -d'=' -f2)
        if [ -n "$value" ] && [ "$value" != "claim-xxxxxxxxxxxxxxxx" ]; then
            echo -e "${GREEN}✅ $var definida${NC}"
        else
            echo -e "${YELLOW}⚠️  $var definida pero con valor por defecto${NC}"
        fi
    else
        echo -e "${RED}❌ $var no encontrada en .env${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# 4. Verificar valores null en configuración
echo "4️⃣  Verificando valores null..."
if docker-compose config 2>/dev/null | grep -q ": null"; then
    echo -e "${RED}❌ Variables con valor null detectadas:${NC}"
    docker-compose config | grep ": null"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✅ No hay valores null${NC}"
fi
echo ""

# 5. Verificar puertos disponibles
echo "5️⃣  Verificando disponibilidad de puertos..."
PORTS=(32400 5055 8989 7878 9696 6767 8089 3000 9090 8080 9100)
PORT_CONFLICTS=0

for port in "${PORTS[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Puerto $port en uso${NC}"
        PORT_CONFLICTS=$((PORT_CONFLICTS + 1))
    else
        echo -e "${GREEN}✅ Puerto $port disponible${NC}"
    fi
done

if [ $PORT_CONFLICTS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $PORT_CONFLICTS puerto(s) en uso (puede ser producción activa)${NC}"
fi
echo ""

# 6. Verificar directorios de volúmenes
echo "6️⃣  Verificando directorios de volúmenes..."
VOLUME_VARS=(
    "PLEX_CONFIG_VOLUME"
    "SONARR_CONFIG_VOLUME"
    "RADARR_CONFIG_VOLUME"
    "BAZARR_CONFIG_VOLUME"
    "PROWLARR_CONFIG_VOLUME"
    "OVERSEERR_CONFIG_VOLUME"
    "QBITTORRENT_CONFIG_VOLUME"
    "TV_SERIES_VOLUME"
    "MOVIES_VOLUME"
    "DOWNLOADS_VOLUME"
)

for var in "${VOLUME_VARS[@]}"; do
    if grep -q "^${var}=" .env 2>/dev/null; then
        path=$(grep "^${var}=" .env | cut -d'=' -f2)
        if [ -d "$path" ]; then
            echo -e "${GREEN}✅ $var: $path existe${NC}"
        else
            echo -e "${YELLOW}⚠️  $var: $path no existe (se creará al iniciar)${NC}"
        fi
    fi
done
echo ""

# 7. Verificar permisos
echo "7️⃣  Verificando permisos de usuario..."
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
ENV_PUID=$(grep "^PUID=" .env 2>/dev/null | cut -d'=' -f2)
ENV_PGID=$(grep "^PGID=" .env 2>/dev/null | cut -d'=' -f2)

if [ "$CURRENT_UID" = "$ENV_PUID" ] && [ "$CURRENT_GID" = "$ENV_PGID" ]; then
    echo -e "${GREEN}✅ PUID/PGID coinciden con usuario actual${NC}"
else
    echo -e "${YELLOW}⚠️  PUID/PGID no coinciden:${NC}"
    echo "   Usuario actual: UID=$CURRENT_UID GID=$CURRENT_GID"
    echo "   En .env: PUID=$ENV_PUID PGID=$ENV_PGID"
fi
echo ""

# Resumen final
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Validación completada sin errores${NC}"
    echo ""
    echo "Puedes proceder con:"
    echo "  docker-compose up -d"
    exit 0
else
    echo -e "${RED}❌ Validación completada con $ERRORS error(es)${NC}"
    echo ""
    echo "Corrige los errores antes de continuar"
    exit 1
fi
