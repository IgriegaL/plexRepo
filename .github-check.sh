#!/bin/bash
# Script para verificar que no se suban archivos sensibles a GitHub
# Ejecutar ANTES de hacer git push

echo "🔍 Verificando archivos sensibles antes de subir a GitHub..."
echo ""

ERRORS=0

# Verificar que .env no esté en el repo
if git ls-files | grep -q "^\.env$"; then
    echo "❌ ERROR: Archivo .env está en el repositorio"
    echo "   Ejecuta: git rm --cached .env"
    ERRORS=$((ERRORS + 1))
fi

# Verificar que no haya secrets
if git ls-files | grep -q "secrets/"; then
    echo "❌ ERROR: Carpeta secrets/ está en el repositorio"
    echo "   Ejecuta: git rm -r --cached secrets/"
    ERRORS=$((ERRORS + 1))
fi

# Verificar que no haya archivos .key, .pem, .crt
if git ls-files | grep -E "\.(key|pem|crt)$"; then
    echo "❌ ERROR: Archivos de certificados en el repositorio"
    echo "   Ejecuta: git rm --cached <archivo>"
    ERRORS=$((ERRORS + 1))
fi

# Verificar que no haya bases de datos
if git ls-files | grep -E "\.(db|sqlite|sqlite3)$"; then
    echo "❌ ERROR: Bases de datos en el repositorio"
    echo "   Ejecuta: git rm --cached <archivo>"
    ERRORS=$((ERRORS + 1))
fi

# Verificar que no haya backups
if git ls-files | grep -E "\.(bak|backup|gpg)$"; then
    echo "❌ ERROR: Archivos de backup en el repositorio"
    echo "   Ejecuta: git rm --cached <archivo>"
    ERRORS=$((ERRORS + 1))
fi

# Verificar que no haya logs
if git ls-files | grep -E "\.log$"; then
    echo "❌ ERROR: Archivos de log en el repositorio"
    echo "   Ejecuta: git rm --cached <archivo>"
    ERRORS=$((ERRORS + 1))
fi

# Verificar que .gitignore exista
if [ ! -f ".gitignore" ]; then
    echo "❌ ERROR: No existe archivo .gitignore"
    ERRORS=$((ERRORS + 1))
fi

# Verificar que .env.example exista
if [ ! -f ".env.example" ]; then
    echo "⚠️  ADVERTENCIA: No existe .env.example"
    echo "   Se recomienda tener una plantilla de configuración"
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ Todo correcto - Seguro para subir a GitHub"
    echo ""
    echo "Próximos pasos:"
    echo "  git add ."
    echo "  git commit -m 'Tu mensaje'"
    echo "  git push"
    exit 0
else
    echo "❌ Se encontraron $ERRORS errores"
    echo "   Corrige los errores antes de subir a GitHub"
    exit 1
fi
