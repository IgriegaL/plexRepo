#!/bin/bash
# Escanear vulnerabilidades en imágenes Docker
# Uso: ./scripts/security/scan-vulnerabilities.sh

set -e

echo "🔍 Escaneando vulnerabilidades en imágenes Docker..."
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directorio de reportes
REPORT_DIR="./trivy/reports"
mkdir -p "$REPORT_DIR"

# Imágenes a escanear
IMAGES=(
    "lscr.io/linuxserver/plex:latest"
    "lscr.io/linuxserver/sonarr:latest"
    "lscr.io/linuxserver/radarr:latest"
    "lscr.io/linuxserver/prowlarr:latest"
    "lscr.io/linuxserver/bazarr:latest"
    "lscr.io/linuxserver/overseerr:latest"
    "lscr.io/linuxserver/qbittorrent:latest"
    "lscr.io/linuxserver/tautulli:latest"
    "grafana/grafana:latest"
    "prom/prometheus:latest"
    "traefik:v2.10"
    "authelia/authelia:latest"
)

CRITICAL=0
HIGH=0
MEDIUM=0

for image in "${IMAGES[@]}"; do
    echo "Escaneando: $image"
    
    # Escanear
    docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$REPORT_DIR:/reports" \
        aquasec/trivy:latest image \
        --severity CRITICAL,HIGH,MEDIUM \
        --format json \
        --output "/reports/$(echo $image | tr '/:' '_').json" \
        "$image" 2>/dev/null || true
    
    # Contar vulnerabilidades
    if [ -f "$REPORT_DIR/$(echo $image | tr '/:' '_').json" ]; then
        crit=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "$REPORT_DIR/$(echo $image | tr '/:' '_').json" 2>/dev/null || echo 0)
        high=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "$REPORT_DIR/$(echo $image | tr '/:' '_').json" 2>/dev/null || echo 0)
        med=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' "$REPORT_DIR/$(echo $image | tr '/:' '_').json" 2>/dev/null || echo 0)
        
        CRITICAL=$((CRITICAL + crit))
        HIGH=$((HIGH + high))
        MEDIUM=$((MEDIUM + med))
        
        if [ "$crit" -gt 0 ]; then
            echo -e "${RED}  ❌ CRITICAL: $crit${NC}"
        fi
        if [ "$high" -gt 0 ]; then
            echo -e "${YELLOW}  ⚠️  HIGH: $high${NC}"
        fi
        if [ "$med" -gt 0 ]; then
            echo "  ℹ️  MEDIUM: $med"
        fi
        if [ "$crit" -eq 0 ] && [ "$high" -eq 0 ] && [ "$med" -eq 0 ]; then
            echo -e "${GREEN}  ✅ Sin vulnerabilidades${NC}"
        fi
    fi
    echo ""
done

# Resumen
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Resumen Total:"
echo -e "   ${RED}CRITICAL: $CRITICAL${NC}"
echo -e "   ${YELLOW}HIGH: $HIGH${NC}"
echo "   MEDIUM: $MEDIUM"
echo ""
echo "Reportes guardados en: $REPORT_DIR"
echo ""

if [ "$CRITICAL" -gt 0 ]; then
    echo -e "${RED}⚠️  ATENCIÓN: Se encontraron vulnerabilidades CRÍTICAS${NC}"
    echo "   Revisa los reportes y actualiza las imágenes afectadas"
    exit 1
elif [ "$HIGH" -gt 5 ]; then
    echo -e "${YELLOW}⚠️  ADVERTENCIA: Múltiples vulnerabilidades HIGH${NC}"
    echo "   Considera actualizar las imágenes afectadas"
    exit 0
else
    echo -e "${GREEN}✅ Nivel de vulnerabilidades aceptable${NC}"
    exit 0
fi
