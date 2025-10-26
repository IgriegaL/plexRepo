#!/bin/bash
# Script para generar secrets de Authelia
# Uso: ./scripts/security/generate-secrets.sh

set -e

echo "🔐 Generando secrets para Authelia..."
echo ""

# Crear directorio de secrets
mkdir -p secrets

# Generar JWT secret
echo "Generando JWT secret..."
openssl rand -hex 32 > secrets/authelia_jwt_secret.txt

# Generar Session secret
echo "Generando Session secret..."
openssl rand -hex 32 > secrets/authelia_session_secret.txt

# Generar Storage encryption key
echo "Generando Storage encryption key..."
openssl rand -hex 32 > secrets/authelia_storage_key.txt

# Permisos seguros
chmod 600 secrets/*.txt

echo ""
echo "✅ Secrets generados en ./secrets/"
echo ""
echo "⚠️  IMPORTANTE: Estos archivos contienen información sensible."
echo "   NO los subas a Git (ya están en .gitignore)"
echo ""
echo "Archivos creados:"
ls -lh secrets/

echo ""
echo "Próximo paso: Generar password hash para usuarios"
echo "Ejecuta: docker run authelia/authelia:latest authelia crypto hash generate argon2 --password 'tu_password'"
