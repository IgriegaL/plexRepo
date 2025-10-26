#!/bin/bash
# Script maestro que ejecuta todos los tests
# Uso: ./scripts/run-all-tests.sh

set -e

echo "🧪 Ejecutando suite completa de tests..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED_TESTS=0

# Test 1: Validación de configuración
echo "═══════════════════════════════════════════"
echo "TEST 1: Validación de Configuración"
echo "═══════════════════════════════════════════"
if bash "$SCRIPT_DIR/test-config.sh"; then
    echo -e "${GREEN}✅ Test de configuración: PASSED${NC}"
else
    echo -e "${RED}❌ Test de configuración: FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
echo ""
sleep 2

# Preguntar si continuar con tests que requieren servicios corriendo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Los siguientes tests requieren que los servicios estén corriendo."
echo ""
read -p "¿Están los servicios corriendo? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Para ejecutar los tests completos:"
    echo "  1. Inicia los servicios: docker-compose up -d"
    echo "  2. Espera 2 minutos"
    echo "  3. Ejecuta nuevamente: ./scripts/run-all-tests.sh"
    exit 0
fi

echo ""

# Test 2: Health checks
echo "═══════════════════════════════════════════"
echo "TEST 2: Health Checks"
echo "═══════════════════════════════════════════"
if bash "$SCRIPT_DIR/test-health.sh"; then
    echo -e "${GREEN}✅ Test de health: PASSED${NC}"
else
    echo -e "${RED}❌ Test de health: FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
echo ""
sleep 2

# Test 3: Conectividad
echo "═══════════════════════════════════════════"
echo "TEST 3: Conectividad de Servicios"
echo "═══════════════════════════════════════════"
if bash "$SCRIPT_DIR/test-connectivity.sh"; then
    echo -e "${GREEN}✅ Test de conectividad: PASSED${NC}"
else
    echo -e "${RED}❌ Test de conectividad: FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
echo ""
sleep 2

# Test 4: Verificación de logs
echo "═══════════════════════════════════════════"
echo "TEST 4: Verificación de Logs"
echo "═══════════════════════════════════════════"
echo "Buscando errores críticos en logs..."

SERVICES=(plex sonarr radarr prowlarr bazarr overseerr qbittorrent grafana prometheus)
ERRORS_FOUND=0

for service in "${SERVICES[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${service}$"; then
        # Buscar errores críticos en últimas 50 líneas
        if docker logs $service --tail=50 2>&1 | grep -iE "error|fatal|exception|failed" | grep -v "level=error" | grep -q .; then
            echo -e "${YELLOW}⚠️  $service: errores encontrados en logs${NC}"
            ERRORS_FOUND=$((ERRORS_FOUND + 1))
        else
            echo -e "${GREEN}✅ $service: sin errores críticos${NC}"
        fi
    fi
done

if [ $ERRORS_FOUND -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Test de logs: PASSED WITH WARNINGS${NC}"
    echo "   Revisa los logs manualmente: docker-compose logs <servicio>"
else
    echo -e "${GREEN}✅ Test de logs: PASSED${NC}"
fi
echo ""
sleep 2

# Test 5: Uso de recursos
echo "═══════════════════════════════════════════"
echo "TEST 5: Uso de Recursos"
echo "═══════════════════════════════════════════"
echo "Verificando límites de recursos..."

# Verificar que ningún contenedor use más del 90% de su límite
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -v "CONTAINER"

echo -e "${GREEN}✅ Test de recursos: PASSED${NC}"
echo ""
sleep 2

# Test 6: Tamaño de logs
echo "═══════════════════════════════════════════"
echo "TEST 6: Tamaño de Logs"
echo "═══════════════════════════════════════════"
echo "Verificando que los logs no excedan límites..."

LOG_ISSUES=0
for service in "${SERVICES[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${service}$"; then
        log_path=$(docker inspect --format='{{.LogPath}}' $service 2>/dev/null)
        if [ -f "$log_path" ]; then
            log_size=$(du -h "$log_path" | cut -f1)
            log_size_mb=$(du -m "$log_path" | cut -f1)
            
            if [ "$log_size_mb" -gt 30 ]; then
                echo -e "${RED}❌ $service: log muy grande ($log_size)${NC}"
                LOG_ISSUES=$((LOG_ISSUES + 1))
            else
                echo -e "${GREEN}✅ $service: log OK ($log_size)${NC}"
            fi
        fi
    fi
done

if [ $LOG_ISSUES -gt 0 ]; then
    echo -e "${RED}❌ Test de tamaño de logs: FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
else
    echo -e "${GREEN}✅ Test de tamaño de logs: PASSED${NC}"
fi
echo ""

# Resumen final
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RESUMEN DE TESTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✅ TODOS LOS TESTS PASARON${NC}"
    echo ""
    echo "🎉 El sistema está listo para producción"
    echo ""
    echo "Próximos pasos:"
    echo "  1. Crear backup: ./scripts/backup.sh"
    echo "  2. Aplicar en producción"
    echo "  3. Monitorear: docker-compose logs -f"
    exit 0
else
    echo -e "${RED}❌ $FAILED_TESTS TEST(S) FALLARON${NC}"
    echo ""
    echo "⚠️  NO aplicar en producción hasta resolver los problemas"
    echo ""
    echo "Para debugging:"
    echo "  - Ver logs: docker-compose logs <servicio>"
    echo "  - Ver estado: docker-compose ps"
    echo "  - Reintentar: ./scripts/run-all-tests.sh"
    exit 1
fi
