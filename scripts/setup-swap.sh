#!/bin/bash

# Script para configurar swap en Orange Pi 5 Pro
# Recomendado: 4GB de swap para prevenir crashes por falta de memoria
# Uso: sudo ./scripts/setup-swap.sh

set -e

if [ "$(uname -s)" = Darwin ]; then
    echo "En macOS la memoria de los contenedores la define la VM de Colima."
    echo "Para darle más RAM:  colima stop && colima start --memory 10"
    exit 0
fi

SWAP_SIZE=${1:-4G}
SWAP_FILE="/swapfile"

echo "🔧 Configurando Swap de $SWAP_SIZE..."
echo ""

# Verificar si ya existe swap
if [ "$(swapon --show | wc -l)" -gt 0 ]; then
    echo "⚠️  Ya existe swap configurado:"
    swapon --show
    echo ""
    
    # Verificar cuánto swap está en uso
    SWAP_USED=$(free -m | awk '/^Swap/{print $3}')
    if [ "$SWAP_USED" -gt 100 ]; then
        echo "⚠️  Swap en uso: ${SWAP_USED}MB"
        echo "   Para cambiar el tamaño sin interrupciones:"
        echo "   1. Reinicie el sistema primero"
        echo "   2. Ejecute este script de nuevo"
        echo ""
        read -p "¿Continuar de todas formas? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Operación cancelada."
            exit 0
        fi
    else
        read -p "¿Desea reemplazarlo? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Operación cancelada."
            exit 0
        fi
    fi
    
    echo "Desactivando swap actual (esto puede tomar tiempo)..."
    swapoff -a 2>/dev/null || {
        echo "❌ Error: No se pudo desactivar swap (sistema bajo presión de memoria)"
        echo "   Libere memoria primero o reinicie el sistema."
        exit 1
    }
    rm -f "$SWAP_FILE"
fi

# Crear archivo de swap
echo "Creando archivo de swap de $SWAP_SIZE..."
fallocate -l "$SWAP_SIZE" "$SWAP_FILE"

# Configurar permisos
echo "Configurando permisos..."
chmod 600 "$SWAP_FILE"

# Formatear como swap
echo "Formateando como swap..."
mkswap "$SWAP_FILE"

# Activar swap
echo "Activando swap..."
swapon "$SWAP_FILE"

# Hacer permanente (añadir a /etc/fstab si no existe)
if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "Haciendo swap permanente (añadiendo a /etc/fstab)..."
    echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
fi

# Configurar swappiness (agresividad del swap)
echo "Configurando swappiness..."
sysctl vm.swappiness=10
if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
    echo "vm.swappiness=10" >> /etc/sysctl.conf
fi

echo ""
echo "✅ Swap configurado correctamente:"
swapon --show
free -h
echo ""
echo "💡 Nota: swappiness=10 significa que el sistema preferirá usar RAM"
echo "   y solo usará swap cuando sea necesario (reduce desgaste de disco)."
