#!/bin/bash
# Escanear descargas con ClamAV
# Uso: ./scripts/security/scan-downloads.sh

set -e

echo "🦠 Escaneando descargas con ClamAV..."
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar que ClamAV está corriendo
if ! docker ps | grep -q clamav; then
    echo -e "${RED}❌ ClamAV no está corriendo${NC}"
    echo "Inicia el servicio: docker-compose -f docker-compose.security.yml up -d clamav"
    exit 1
fi

# Esperar a que ClamAV esté listo
echo "Esperando a que ClamAV esté listo..."
sleep 5

# Escanear
echo "Escaneando /scan (descargas)..."
docker exec clamav clamscan \
    -r \
    --infected \
    --remove \
    --log=/var/log/clamav/scan.log \
    /scan

# Verificar resultado
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Escaneo completado - No se encontraron amenazas${NC}"
elif [ $? -eq 1 ]; then
    echo -e "${RED}❌ ALERTA: Se encontraron archivos infectados${NC}"
    echo "Los archivos infectados han sido movidos a cuarentena"
    
    # Enviar notificación
    if command -v curl &> /dev/null; then
        curl -X POST http://localhost:8000/notify/apprise \
            -d "title=🦠 ClamAV - Amenaza Detectada" \
            -d "body=Se encontraron archivos infectados en las descargas. Revisa los logs." \
            2>/dev/null || true
    fi
    exit 1
else
    echo -e "${YELLOW}⚠️  Error durante el escaneo${NC}"
    exit 1
fi

# Mostrar estadísticas
echo ""
echo "📊 Estadísticas del escaneo:"
docker exec clamav tail -20 /var/log/clamav/scan.log | grep -E "Infected files|Scanned files|Time"
