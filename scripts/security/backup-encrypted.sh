#!/bin/bash
# Crear backup encriptado
# Uso: ./scripts/security/backup-encrypted.sh

set -e

echo "💾 Creando backup encriptado..."
echo ""

# Configuración
BACKUP_DIR="$HOME/plex-backups-encrypted"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="plex-backup-${TIMESTAMP}"
PASSWORD_FILE="./secrets/backup_password.txt"

# Crear directorio
mkdir -p "$BACKUP_DIR"

# Verificar password
if [ ! -f "$PASSWORD_FILE" ]; then
    echo "⚠️  No se encontró archivo de password"
    echo "Generando password aleatorio..."
    openssl rand -base64 32 > "$PASSWORD_FILE"
    chmod 600 "$PASSWORD_FILE"
    echo "✅ Password guardado en: $PASSWORD_FILE"
    echo "   GUARDA ESTE ARCHIVO EN UN LUGAR SEGURO"
fi

# Crear backup
echo "1️⃣  Creando archivo tar..."
tar -czf "/tmp/${BACKUP_NAME}.tar.gz" \
    --exclude='*.log' \
    --exclude='cache' \
    --exclude='tmp' \
    docker-compose*.yml \
    .env \
    authelia/ \
    fail2ban/ \
    traefik/ \
    grafana/ \
    prometheus.yml \
    scripts/ \
    2>/dev/null || true

# Encriptar
echo "2️⃣  Encriptando backup..."
gpg --batch --yes \
    --passphrase-file "$PASSWORD_FILE" \
    --symmetric \
    --cipher-algo AES256 \
    --output "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz.gpg" \
    "/tmp/${BACKUP_NAME}.tar.gz"

# Limpiar
rm "/tmp/${BACKUP_NAME}.tar.gz"

# Calcular hash
echo "3️⃣  Calculando checksum..."
sha256sum "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz.gpg" > "${BACKUP_DIR}/${BACKUP_NAME}.sha256"

# Tamaño
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz.gpg" | cut -f1)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Backup encriptado completado"
echo ""
echo "📊 Información:"
echo "   Archivo: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz.gpg"
echo "   Tamaño: $BACKUP_SIZE"
echo "   Checksum: ${BACKUP_DIR}/${BACKUP_NAME}.sha256"
echo ""
echo "🔐 Para restaurar:"
echo "   gpg --decrypt --passphrase-file $PASSWORD_FILE ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz.gpg | tar -xzf -"
echo ""
echo "⚠️  IMPORTANTE: Guarda el archivo de password en un lugar seguro"
echo "   Sin él, NO podrás restaurar el backup"
