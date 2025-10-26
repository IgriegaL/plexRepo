#!/bin/bash
# Script de verificación de healthchecks
# Uso: ./scripts/test-health.sh

echo "🏥 Verificando estado de salud de servicios..."
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Servicios con healthcheck
SERVICES=(plex bazarr qbittorrent sonarr radarr overseerr prowlarr prometheus grafana)

HEALTHY=0
STARTING=0
UNHEALTHY=0
NOT_RUNNING=0

for service in "${SERVICES[@]}"; do
    # Verificar si el contenedor existe
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${service}$"; then
        echo -e "${RED}❌ $service: contenedor no existe${NC}"
        NOT_RUNNING=$((NOT_RUNNING + 1))
        continue
    fi
    
    # Verificar si está corriendo
    if ! docker ps --format '{{.Names}}' | grep -q "^${service}$"; then
        echo -e "${RED}❌ $service: contenedor detenido${NC}"
        NOT_RUNNING=$((NOT_RUNNING + 1))
        continue
    fi
    
    # Obtener estado de salud
    health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' $service 2>/dev/null)
    
    case "$health" in
        "healthy")
            echo -e "${GREEN}✅ $service: healthy${NC}"
            HEALTHY=$((HEALTHY + 1))
            ;;
        "starting")
            echo -e "${YELLOW}⏳ $service: starting...${NC}"
            STARTING=$((STARTING + 1))
            ;;
        "unhealthy")
            echo -e "${RED}❌ $service: unhealthy${NC}"
            UNHEALTHY=$((UNHEALTHY + 1))
            # Mostrar últimos logs
            echo -e "${BLUE}   Últimos logs:${NC}"
            docker logs $service --tail=5 2>&1 | sed 's/^/   /'
            ;;
        "no-healthcheck")
            echo -e "${BLUE}ℹ️  $service: sin healthcheck configurado${NC}"
            ;;
        *)
            echo -e "${RED}❌ $service: estado desconocido ($health)${NC}"
            UNHEALTHY=$((UNHEALTHY + 1))
            ;;
    esac
done

# Servicios sin healthcheck pero importantes
echo ""
echo "📊 Servicios de monitoreo (sin healthcheck):"
MONITORING_SERVICES=(cadvisor node_exporter)

for service in "${MONITORING_SERVICES[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${service}$"; then
        echo -e "${GREEN}✅ $service: running${NC}"
    else
        echo -e "${RED}❌ $service: no running${NC}"
        NOT_RUNNING=$((NOT_RUNNING + 1))
    fi
done

# Resumen
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📈 Resumen:"
echo -e "   ${GREEN}Healthy: $HEALTHY${NC}"
echo -e "   ${YELLOW}Starting: $STARTING${NC}"
echo -e "   ${RED}Unhealthy: $UNHEALTHY${NC}"
echo -e "   ${RED}Not running: $NOT_RUNNING${NC}"
echo ""

if [ $STARTING -gt 0 ]; then
    echo -e "${YELLOW}⏳ Algunos servicios aún están iniciando. Espera 1-2 minutos y vuelve a ejecutar.${NC}"
fi

if [ $UNHEALTHY -gt 0 ] || [ $NOT_RUNNING -gt 0 ]; then
    echo -e "${RED}❌ Hay servicios con problemas. Revisa los logs:${NC}"
    echo "   docker-compose logs <servicio>"
    exit 1
else
    echo -e "${GREEN}✅ Todos los servicios están saludables${NC}"
    exit 0
fi
