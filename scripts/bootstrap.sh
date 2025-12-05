#!/bin/bash
set -e

# Function to log messages
log() {
    echo "[BOOTSTRAP] $1"
}

# Function to wait for a service to be ready
wait_for_service() {
    local url="$1"
    local name="$2"
    log "Waiting for $name to be ready at $url..."
    until curl -s "$url" > /dev/null; do
        sleep 5
    done
    log "$name is ready!"
}

# Check if bootstrap is enabled
if [ "$BOOTSTRAP_ENABLE" != "true" ]; then
    log "Bootstrap is disabled. Exiting."
    exit 0
fi

# Install dependencies if missing (jq is essential for JSON parsing)
if ! command -v jq &> /dev/null; then
    log "Installing jq..."
    apk add --no-cache jq curl
fi

# --- Configuration Variables ---
# These should be passed via environment variables in docker-compose
# SONARR_API_KEY, RADARR_API_KEY, PROWLARR_API_KEY, etc.

# 1. Wait for services
wait_for_service "http://sonarr:8989/api/v3/system/status?apikey=$SONARR_API_KEY" "Sonarr"
wait_for_service "http://radarr:7878/api/v3/system/status?apikey=$RADARR_API_KEY" "Radarr"
wait_for_service "http://prowlarr:9696/api/v1/system/status?apikey=$PROWLARR_API_KEY" "Prowlarr"
wait_for_service "http://qbittorrent:$QBITTORRENT_WEBUI_PORT" "qBittorrent"

# 2. Configure Download Client (qBittorrent) in Sonarr
log "Configuring qBittorrent in Sonarr..."
# Check if client already exists
EXISTING_CLIENT=$(curl -s "http://sonarr:8989/api/v3/downloadclient?apikey=$SONARR_API_KEY" | jq -r '.[] | select(.name=="qBittorrent") | .id')

if [ -z "$EXISTING_CLIENT" ]; then
    curl -s -X POST "http://sonarr:8989/api/v3/downloadclient?apikey=$SONARR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"enable\": true,
            \"protocol\": \"torrent\",
            \"priority\": 1,
            \"name\": \"qBittorrent\",
            \"implementation\": \"QBittorrent\",
            \"settings\": {
                \"host\": \"qbittorrent\",
                \"port\": $QBITTORRENT_WEBUI_PORT,
                \"useSsl\": false,
                \"username\": \"$QBITTORRENT_USER\",
                \"password\": \"$QBITTORRENT_PASS\",
                \"tvCategory\": \"tv-sonarr\",
                \"recentTvPriority\": 1,
                \"olderTvPriority\": 1,
                \"initialState\": 0
            },
            \"configContract\": \"QBittorrentSettings\",
            \"implementationName\": \"qBittorrent\",
            \"infoLink\": \"https://wiki.servarr.com/sonarr/supported#qbittorrent\",
            \"tags\": []
        }" > /dev/null
    log "qBittorrent added to Sonarr."
else
    log "qBittorrent already configured in Sonarr."
fi

# 3. Configure Download Client (qBittorrent) in Radarr
log "Configuring qBittorrent in Radarr..."
EXISTING_CLIENT_RADARR=$(curl -s "http://radarr:7878/api/v3/downloadclient?apikey=$RADARR_API_KEY" | jq -r '.[] | select(.name=="qBittorrent") | .id')

if [ -z "$EXISTING_CLIENT_RADARR" ]; then
    curl -s -X POST "http://radarr:7878/api/v3/downloadclient?apikey=$RADARR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"enable\": true,
            \"protocol\": \"torrent\",
            \"priority\": 1,
            \"name\": \"qBittorrent\",
            \"implementation\": \"QBittorrent\",
            \"settings\": {
                \"host\": \"qbittorrent\",
                \"port\": $QBITTORRENT_WEBUI_PORT,
                \"useSsl\": false,
                \"username\": \"$QBITTORRENT_USER\",
                \"password\": \"$QBITTORRENT_PASS\",
                \"movieCategory\": \"radarr\",
                \"initialState\": 0
            },
            \"configContract\": \"QBittorrentSettings\",
            \"implementationName\": \"qBittorrent\",
            \"infoLink\": \"https://wiki.servarr.com/radarr/supported#qbittorrent\",
            \"tags\": []
        }" > /dev/null
    log "qBittorrent added to Radarr."
else
    log "qBittorrent already configured in Radarr."
fi

# 4. Connect Prowlarr to Sonarr and Radarr (Sync App Profiles)
# Note: Prowlarr usually syncs via "Applications" settings.

log "Configuring Sonarr in Prowlarr..."
EXISTING_APP_SONARR=$(curl -s "http://prowlarr:9696/api/v1/applications?apikey=$PROWLARR_API_KEY" | jq -r '.[] | select(.name=="Sonarr") | .id')

if [ -z "$EXISTING_APP_SONARR" ]; then
    curl -s -X POST "http://prowlarr:9696/api/v1/applications?apikey=$PROWLARR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"Sonarr\",
            \"syncLevel\": \"fullSync\",
            \"implementation\": \"Sonarr\",
            \"implementationName\": \"Sonarr\",
            \"configContract\": \"SonarrSettings\",
            \"fields\": [
                { \"name\": \"prowlarrUrl\", \"value\": \"http://prowlarr:9696\" },
                { \"name\": \"baseUrl\", \"value\": \"http://sonarr:8989\" },
                { \"name\": \"apiKey\", \"value\": \"$SONARR_API_KEY\" }
            ]
        }" > /dev/null
    log "Sonarr added to Prowlarr."
else
    log "Sonarr already configured in Prowlarr."
fi

log "Configuring Radarr in Prowlarr..."
EXISTING_APP_RADARR=$(curl -s "http://prowlarr:9696/api/v1/applications?apikey=$PROWLARR_API_KEY" | jq -r '.[] | select(.name=="Radarr") | .id')

if [ -z "$EXISTING_APP_RADARR" ]; then
    curl -s -X POST "http://prowlarr:9696/api/v1/applications?apikey=$PROWLARR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"Radarr\",
            \"syncLevel\": \"fullSync\",
            \"implementation\": \"Radarr\",
            \"implementationName\": \"Radarr\",
            \"configContract\": \"RadarrSettings\",
            \"fields\": [
                { \"name\": \"prowlarrUrl\", \"value\": \"http://prowlarr:9696\" },
                { \"name\": \"baseUrl\", \"value\": \"http://radarr:7878\" },
                { \"name\": \"apiKey\", \"value\": \"$RADARR_API_KEY\" }
            ]
        }" > /dev/null
    log "Radarr added to Prowlarr."
else
    log "Radarr already configured in Prowlarr."
fi

log "Bootstrap completed successfully!"
