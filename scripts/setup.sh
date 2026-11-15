#!/bin/bash
# Instalación / arranque en un solo paso.
# Uso: ./scripts/setup.sh [--claim claim-xxxx]
#
# Funciona en Linux (Docker Engine) y macOS (Colima, se instala solo; o Docker Desktop/OrbStack).
#
# 0. Instala/inicia Docker si hace falta
# 1. Crea .env desde .env.example (PUID/PGID y ADMIN_PASSWORD automáticos)
# 2. Crea las carpetas de configuración y medios con los permisos correctos
# 3. Pide el PLEX_CLAIM solo si Plex aún no está vinculado a tu cuenta
# 4. Levanta el stack y muestra el resultado de la auto-configuración

set -euo pipefail
cd "$(dirname "$0")/.."

CLAIM=""
while [ $# -gt 0 ]; do
    case "$1" in
        --claim) CLAIM="$2"; shift 2 ;;
        *) echo "Opción desconocida: $1"; exit 1 ;;
    esac
done

log() { echo "[SETUP] $1"; }
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"
# Ejecuta sin sudo si se puede (p. ej. carpetas en tu $HOME); si no, con sudo
priv() { "$@" 2>/dev/null || $SUDO "$@"; }

set_env() {
    if grep -q "^$1=" .env; then
        sed -i.tmp "s|^$1=.*|$1=$2|" .env && rm -f .env.tmp
    else
        echo "$1=$2" >> .env
    fi
}
get_env() { grep "^$1=" .env | head -1 | cut -d= -f2-; }

OS="$(uname -s)"

# --- Docker (se instala/inicia solo si hace falta) ---
start_colima() {
    local cpus mem
    cpus=$(sysctl -n hw.ncpu); mem=$(( $(sysctl -n hw.memsize) / 1073741824 ))
    cpus=$(( cpus >= 8 ? cpus / 2 : (cpus >= 4 ? 4 : cpus) ))
    mem=$(( mem >= 16 ? 8 : (mem / 2 > 4 ? mem / 2 : 4) ))
    log "Iniciando Colima (${cpus} CPU / ${mem} GB RAM)..."
    # --network-preferred-route: el tráfico sale por la red nativa de macOS; con la red
    # por defecto (en espacio de usuario) una descarga de qBittorrent deja sin internet
    # a Plex y al resto
    colima start --cpu "$cpus" --memory "$mem" --disk 60 --vm-type vz --mount-type virtiofs \
        --network-address --network-preferred-route \
        || colima start --cpu "$cpus" --memory "$mem" --disk 60
}

ensure_docker_macos() {
    # Instala Colima si no hay Docker, o si hay CLI pero ningún motor corriendo ni Colima
    if ! command -v docker >/dev/null \
        || { ! command -v colima >/dev/null && ! docker info >/dev/null 2>&1; }; then
        command -v brew >/dev/null || { echo "❌ Instala Homebrew primero: https://brew.sh"; exit 1; }
        log "Instalando Colima + Docker CLI + Compose (open source, vía Homebrew)..."
        brew install colima docker docker-compose
    fi
    # Registrar el plugin compose de Homebrew para 'docker compose'
    if ! docker compose version >/dev/null 2>&1 && command -v brew >/dev/null; then
        mkdir -p "$HOME/.docker/cli-plugins"
        ln -sf "$(brew --prefix)/opt/docker-compose/bin/docker-compose" "$HOME/.docker/cli-plugins/docker-compose"
    fi
    if ! docker info >/dev/null 2>&1; then
        if command -v colima >/dev/null; then
            start_colima
        else
            echo "❌ Docker no está corriendo: abre Docker Desktop / OrbStack o instala Colima"; exit 1
        fi
    fi
}

ensure_docker_linux() {
    if ! command -v docker >/dev/null; then
        echo "Docker no está instalado. Se instalará con el script oficial (https://get.docker.com)."
        if [ -t 0 ]; then
            read -r -p "¿Continuar? [S/n] " ans
            case "$ans" in [nN]*) exit 1 ;; esac
        fi
        curl -fsSL https://get.docker.com | $SUDO sh
    fi
    # Docker arranca con el sistema (los contenedores tienen restart: unless-stopped)
    if command -v systemctl >/dev/null; then
        $SUDO systemctl enable --now docker >/dev/null 2>&1 || true
    fi
}

case "$OS" in
    Darwin) ensure_docker_macos ;;
    Linux) ensure_docker_linux ;;
    *) echo "❌ Sistema no soportado: $OS (usa macOS o Linux)"; exit 1 ;;
esac
DOCKER="docker"
docker info >/dev/null 2>&1 || DOCKER="$SUDO docker"
$DOCKER info >/dev/null 2>&1 || { echo "❌ No se puede conectar con Docker"; exit 1; }
$DOCKER compose version >/dev/null 2>&1 || { echo "❌ Falta el plugin 'docker compose' (v2)"; exit 1; }

# --- .env ---
if [ ! -f .env ]; then
    cp .env.example .env
    REAL_USER="${SUDO_USER:-$(id -un)}"
    set_env PUID "$(id -u "$REAL_USER")"
    set_env PGID "$(id -g "$REAL_USER")"
    # Sin los discos de la Orange Pi (o en macOS), todo va a ~/plex-stack
    REAL_HOME=$(eval echo "~$REAL_USER")
    if [ "$OS" = Darwin ] || [ ! -d /mnt/nvme ]; then
        sed -i.tmp "s|/mnt/nvme/docker-volumes|$REAL_HOME/plex-stack/config|" .env && rm -f .env.tmp
    fi
    if [ "$OS" = Darwin ] || [ ! -d /mnt/DiscoDuro ]; then
        sed -i.tmp "s|/mnt/DiscoDuro|$REAL_HOME/plex-stack/media|" .env && rm -f .env.tmp
    fi
    log ".env creado. Rutas: $(get_env PLEX_CONFIG_VOLUME | xargs dirname) y $(get_env MOVIES_VOLUME | xargs dirname)"
fi
if [ -z "$(get_env ADMIN_PASSWORD)" ]; then
    set_env ADMIN_PASSWORD "$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20)"
    log "ADMIN_PASSWORD generado y guardado en .env"
fi

# --- GPU: aceleración por hardware de Plex solo si existe /dev/dri ---
if [ "$OS" = Linux ] && [ -e /dev/dri ]; then
    set_env COMPOSE_FILE "docker-compose.yml"
else
    set_env COMPOSE_FILE "docker-compose.yml:docker-compose.no-gpu.yml"
    log "Sin /dev/dri: Plex usará transcodificación por CPU"
fi

set -a; source .env; set +a

# --- Carpetas ---
log "Creando carpetas..."
for var in $(grep -oE '^[A-Z_]+_VOLUME' .env); do
    dir="${!var}"
    [ -n "$dir" ] && priv mkdir -p "$dir"
done
priv mkdir -p "$DOWNLOADS_VOLUME/incomplete"
for var in $(grep -oE '^[A-Z_]+_VOLUME' .env); do
    dir="${!var}"
    [ -n "$dir" ] && priv chown "$PUID:$PGID" "$dir"
done

# --- Plex claim (solo la primera vez) ---
PREFS="$PLEX_CONFIG_VOLUME/Library/Application Support/Plex Media Server/Preferences.xml"
GREP="grep"
[ -e "$PREFS" ] && [ ! -r "$PREFS" ] && GREP="$SUDO grep"
if ! $GREP -qs 'PlexOnlineToken=' "$PREFS"; then
    if [ -z "$CLAIM" ] && [ -t 0 ]; then
        echo ""
        echo "Plex aún no está vinculado a tu cuenta."
        echo "Abre https://www.plex.tv/claim/ y pega el código (Enter para omitir):"
        read -r CLAIM
    fi
    if [ -n "$CLAIM" ]; then
        set_env PLEX_CLAIM "$CLAIM"
        export PLEX_CLAIM="$CLAIM"
    fi
fi

if [ "$OS" = Darwin ]; then
    IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)
    # Plex corre en la VM de Colima y solo anuncia IPs internas: sin esto el
    # Apple TV / la TV lo ven "no disponible"
    if [ -n "$IP" ]; then
        set_env PLEX_ADVERTISE_URL "http://$IP:32400"
        export PLEX_ADVERTISE_URL="http://$IP:32400"
    fi
else
    IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi
IP=${IP:-localhost}

# --- Arranque ---
log "Descargando imágenes..."
$DOCKER compose pull --quiet
log "Levantando servicios..."
$DOCKER compose up -d --remove-orphans

log "Auto-configuración en curso (puede tardar unos minutos la primera vez)..."
$DOCKER logs -f bootstrap || true
STATUS=$($DOCKER inspect -f '{{.State.ExitCode}}' bootstrap)

cat <<EOF

================================================================
 Usuario: $ADMIN_USER   Contraseña: (ADMIN_PASSWORD en .env)

 Overseerr    http://$IP:5055   (entra con tu cuenta de Plex)
 Plex         http://$IP:32400/web
 Sonarr       http://$IP:8989
 Radarr       http://$IP:7878
 Prowlarr     http://$IP:9696   <- agrega aquí tus indexers
 Bazarr       http://$IP:6767   <- elige idiomas de subtítulos
 qBittorrent  http://$IP:8089
 Tautulli     http://$IP:8181
 Portainer    http://$IP:9000
 Dozzle       http://$IP:8888
 Netdata      http://$IP:19999
================================================================
EOF
if [ "$OS" = Darwin ] && command -v colima >/dev/null; then
    echo "💡 Para que arranque solo al iniciar sesión: colima stop && brew services start colima"
fi
if [ "$STATUS" != "0" ]; then
    echo "⚠️  La auto-configuración terminó con advertencias (ver arriba)."
    echo "   Corrige y vuelve a ejecutar: docker compose run --rm bootstrap"
    exit 1
fi
