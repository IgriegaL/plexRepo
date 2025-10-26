# Compatibilidad ARM64 (aarch64)

Este documento lista la compatibilidad de todos los servicios con arquitectura ARM64.

## ✅ Servicios Base (docker-compose.yml)

Todos los servicios base son **100% compatibles** con ARM64:

- ✅ Plex - `lscr.io/linuxserver/plex:latest`
- ✅ Sonarr - `lscr.io/linuxserver/sonarr:latest`
- ✅ Radarr - `lscr.io/linuxserver/radarr:latest`
- ✅ Prowlarr - `lscr.io/linuxserver/prowlarr:latest`
- ✅ Bazarr - `lscr.io/linuxserver/bazarr:latest`
- ✅ Overseerr - `lscr.io/linuxserver/overseerr:latest`
- ✅ qBittorrent - `lscr.io/linuxserver/qbittorrent:latest`
- ✅ Grafana - `grafana/grafana:latest`
- ✅ Prometheus - `prom/prometheus:latest`
- ✅ cAdvisor - `gcr.io/cadvisor/cadvisor:latest`
- ✅ Node Exporter - `prom/node-exporter:latest`

## ✅ Servicios Avanzados (docker-compose.advanced.yml)

La mayoría son compatibles con ARM64:

- ✅ Traefik - `traefik:v2.10`
- ✅ Gluetun (VPN) - `qmcgaw/gluetun:latest`
- ✅ Watchtower - `containrrr/watchtower:latest`
- ✅ Tautulli - `lscr.io/linuxserver/tautulli:latest`
- ⚠️ Organizr - `organizr/organizr:latest` (soporte limitado, puede fallar)
- ✅ Apprise - `caronc/apprise:latest`
- ✅ Unpackerr - `golift/unpackerr:latest`

**Nota:** Si Organizr falla, puedes comentarlo o usar Homepage como alternativa.

## ✅ Servicios Extras ARM64 (docker-compose.extras-arm64.yml)

Servicios verificados para ARM64:

- ✅ Recyclarr - `ghcr.io/recyclarr/recyclarr:latest`
- ✅ Uptime Kuma - `louislam/uptime-kuma:latest`
- ✅ Kometa - `kometateam/kometa:latest` (con `platform: linux/arm64`)
- ✅ Homepage - `ghcr.io/gethomepage/homepage:latest`
- ✅ Maintainerr - `ghcr.io/jorenn92/maintainerr:latest` (con `platform: linux/arm64`)

### ❌ Excluidos (no disponibles en ARM64):
- ❌ Scrutiny - No tiene imagen ARM64
- ❌ Requestrr - Soporte inestable/no disponible
- ❌ Autoscan - Soporte inestable/no disponible

## ✅ Servicios de Seguridad ARM64 (docker-compose.security-arm64.yml)

Todos compatibles con ARM64:

- ✅ Authelia - `authelia/authelia:latest`
- ✅ Fail2ban - `crazymax/fail2ban:latest`
- ✅ Loki - `grafana/loki:latest`
- ✅ Promtail - `grafana/promtail:latest`

### ❌ Servicios de seguridad excluidos (no disponibles en ARM64):
- ❌ ClamAV - No tiene imagen ARM64 confiable
- ❌ CrowdSec - No tiene imagen ARM64
- ❌ Trivy - No tiene imagen ARM64
- ❌ ModSecurity - No tiene imagen ARM64

## 🚀 Comando Recomendado para ARM64

```bash
# Verificar arquitectura
uname -m  # Debe mostrar: aarch64 o arm64

# Levantar stack completo ARM64
docker compose -f docker-compose.yml \
  -f docker-compose.advanced.yml \
  -f docker-compose.extras-arm64.yml \
  -f docker-compose.security-arm64.yml \
  up -d
```

## ⚠️ Troubleshooting

### Error: "no matching manifest for linux/arm64"

Si ves este error, significa que algún servicio no tiene soporte ARM64:

1. Identifica qué servicio está fallando en los logs
2. Comenta ese servicio en el archivo yml correspondiente
3. Vuelve a ejecutar el comando

### Servicios con problemas conocidos en ARM64:

- **Organizr**: Puede fallar al descargar. Alternativa: usa Homepage
- **Scrutiny**: No disponible. Alternativa: usa `smartmontools` o Netdata
- **Requestrr**: No disponible. Alternativa: usa Overseerr directamente
- **Autoscan**: No disponible. Alternativa: configuración manual de Plex

## 📊 Resumen de Compatibilidad

| Categoría | Total | Compatible | No Compatible | % Compatibilidad |
|-----------|-------|------------|---------------|------------------|
| Base | 11 | 11 | 0 | 100% |
| Avanzados | 7 | 6-7 | 0-1 | 85-100% |
| Extras | 8 | 5 | 3 | 62% |
| Seguridad | 8 | 5 | 3 | 62% |
| **TOTAL** | **34** | **27-28** | **6-7** | **79-82%** |

## 🔄 Última Actualización

**Fecha:** 26 de Octubre, 2025  
**Versión:** 2.3.0  
**Arquitectura probada:** ARM64 (aarch64) - Oracle Cloud, Raspberry Pi 4/5
