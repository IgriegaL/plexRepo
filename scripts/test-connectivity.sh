#!/bin/bash
# Script de verificación de conectividad
# Uso: ./scripts/test-connectivity.sh

echo "🌐 Probando conectividad a servicios..."
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Array asociativo de servicios y puertos
declare -A SERVICES=(
    ["Plex"]="32400"
    ["Overseerr"]="5055"
    ["Sonarr"]="8989"
    ["Radarr"]="7878"
    ["Prowlarr"]="9696"
    ["Bazarr"]="6767"
    ["qBittorrent"]="8089"
    ["Grafana"]="3000"
    ["Prometheus"]="9090"
    ["cAdvisor"]="8080"
    ["Node Exporter"]="9100"
)

ACCESSIBLE=0
NOT_ACCESSIBLE=0

for service in "${!SERVICES[@]}"; do
    port=${SERVICES[$service]}
    
    # Intentar conectar con timeout de 5 segundos
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://localhost:$port 2>/dev/null)
    
    # Códigos de éxito: 200 (OK), 302 (Redirect), 401 (Auth required), 403 (Forbidden)
    if [[ "$http_code" =~ ^(200|302|401|403)$ ]]; then
        echo -e "${GREEN}✅ $service (puerto $port): accesible [HTTP $http_code]${NC}"
        ACCESSIBLE=$((ACCESSIBLE + 1))
    else
        echo -e "${RED}❌ $service (puerto $port): no responde [HTTP $http_code]${NC}"
        NOT_ACCESSIBLE=$((NOT_ACCESSIBLE + 1))
        
        # Verificar si el puerto está escuchando
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "${YELLOW}   ⚠️  Puerto escuchando pero no responde HTTP${NC}"
        else
            echo -e "${YELLOW}   ⚠️  Puerto no está escuchando${NC}"
        fi
    fi
done

# Resumen
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Resumen de conectividad:"
echo -e "   ${GREEN}Accesibles: $ACCESSIBLE${NC}"
echo -e "   ${RED}No accesibles: $NOT_ACCESSIBLE${NC}"
echo ""

if [ $NOT_ACCESSIBLE -eq 0 ]; then
    echo -e "${GREEN}✅ Todos los servicios son accesibles${NC}"
    echo ""
    echo "URLs de acceso:"
    echo "  Plex:        http://localhost:32400/web"
    echo "  Overseerr:   http://localhost:5055"
    echo "  Sonarr:      http://localhost:8989"
    echo "  Radarr:      http://localhost:7878"
    echo "  Prowlarr:    http://localhost:9696"
    echo "  Bazarr:      http://localhost:6767"
    echo "  qBittorrent: http://localhost:8089"
    echo "  Grafana:     http://localhost:3000"
    echo "  Prometheus:  http://localhost:9090"
    exit 0
else
    echo -e "${RED}❌ Algunos servicios no son accesibles${NC}"
    echo ""
    echo "Verifica:"
    echo "  1. Los contenedores están corriendo: docker-compose ps"
    echo "  2. Los healthchecks están pasando: ./scripts/test-health.sh"
    echo "  3. Los logs no muestran errores: docker-compose logs <servicio>"
    exit 1
fi
