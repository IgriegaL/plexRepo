#!/bin/bash

# Script de monitoreo de recursos para Orange Pi 5 Pro
# Uso: ./scripts/monitor.sh

set -e

echo "🔍 Monitoreo de Recursos - Orange Pi 5 Pro"
echo "=========================================="
echo ""

# Memoria del sistema
echo "📊 Uso de Memoria:"
free -h | grep -v "^Swap" | awk 'NR==1{print "   "$0} NR==2{printf "   Used: %s / %s (%.1f%%)\n", $3, $2, ($3/$2)*100}'
echo ""

# Swap
echo "💾 Uso de Swap:"
free -h | grep "^Swap" | awk '{if($2=="0B" || $2=="0"){print "   ⚠️  Swap NO configurado (recomendado: 4GB)"} else {printf "   Used: %s / %s\n", $3, $2}}'
echo ""

# CPU y temperatura
echo "🔥 CPU y Temperatura:"
CPU_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "0")
CPU_TEMP_C=$((CPU_TEMP / 1000))
uptime | awk '{printf "   Load Average: %s %s %s\n", $(NF-2), $(NF-1), $NF}'
echo "   Temperatura: ${CPU_TEMP_C}°C"
if [ "$CPU_TEMP_C" -gt 75 ]; then
    echo "   ⚠️  Temperatura ALTA (>75°C) - Reducir carga o mejorar refrigeración"
fi
echo ""

# Disco
echo "💿 Uso de Disco:"
df -h | grep -E "(/mnt/nvme|/mnt/DiscoDuro|/$)" | awk '{printf "   %s: %s / %s (%s usado)\n", $6, $3, $2, $5}'
echo ""

# Top 10 contenedores por uso de memoria
echo "🐳 Top 10 Contenedores por Memoria:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | \
    head -n 11 | awk 'NR==1{print "   "$0} NR>1{print "   "$0}'
echo ""

# Contenedores con problemas
echo "⚠️  Contenedores con Problemas:"
PROBLEM_CONTAINERS=$(docker ps -a --filter "status=exited" --filter "status=dead" --filter "status=restarting" --format "{{.Names}} ({{.Status}})" 2>/dev/null || echo "")
if [ -z "$PROBLEM_CONTAINERS" ]; then
    echo "   ✅ Todos los contenedores funcionan correctamente"
else
    echo "$PROBLEM_CONTAINERS" | while read line; do
        echo "   ❌ $line"
    done
fi
echo ""

# Recomendaciones
echo "💡 Recomendaciones:"
TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
USED_MEM=$(free -m | awk 'NR==2{print $3}')
MEM_PERCENT=$((USED_MEM * 100 / TOTAL_MEM))

if [ "$MEM_PERCENT" -gt 85 ]; then
    echo "   ⚠️  Uso de RAM >85% - Considerar reducir límites de contenedores"
fi

SWAP_TOTAL=$(free -m | awk '/^Swap/{print $2}')
if [ "$SWAP_TOTAL" -eq 0 ]; then
    echo "   ⚠️  Sin swap configurado - Ejecutar: sudo ./scripts/setup-swap.sh"
fi

if [ "$CPU_TEMP_C" -gt 70 ]; then
    echo "   ⚠️  Temperatura >70°C - Reducir transcoding o mejorar ventilación"
fi

echo ""
echo "✅ Monitoreo completado. Para monitoreo continuo ejecuta: watch -n 5 ./scripts/monitor.sh"
