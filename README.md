# 🎬 Media Server - Servidor Multimedia Completo

Sistema completo de servidor multimedia con gestión automatizada, monitoreo, notificaciones y funcionalidades avanzadas usando Docker Compose.

> **🎓 ¿Eres nuevo en Linux/Docker?** Lee primero **[GUIA_PRINCIPIANTES.md](GUIA_PRINCIPIANTES.md)** - Te guía paso a paso desde cero hasta tener todo funcionando.

## 📋 Tabla de Contenidos

- [Servicios Incluidos](#-servicios-incluidos)
- [Inicio Rápido](#-inicio-rápido)
- [Configuración Completa](#️-configuración-completa)
- [Servicios Avanzados](#-servicios-avanzados-opcional)
- [Notificaciones](#-notificaciones)
- [Testing](#-testing-y-validación)
- [Puertos](#-puertos-de-acceso)
- [Troubleshooting](#-troubleshooting)

---

## 🎬 Servicios Incluidos

### Media Center (Base)

- **Plex** - Servidor de streaming multimedia
- **qBittorrent** - Cliente de torrents (con VPN opcional)
- **Sonarr** - Gestor automático de series TV
- **Radarr** - Gestor automático de películas
- **Prowlarr** - Gestor de indexadores
- **Bazarr** - Gestor automático de subtítulos
- **Overseerr** - Interfaz de solicitud de contenido

### Monitoreo (Base)

- **Prometheus** - Sistema de métricas
- **Grafana** - Visualización de métricas
- **cAdvisor** - Métricas de contenedores
- **Node Exporter** - Métricas del sistema

### Avanzados (Opcionales)

- **Traefik** - Reverse proxy con SSL automático
- **Gluetun** - VPN para torrents
- **Watchtower** - Auto-actualización de contenedores
- **Tautulli** - Estadísticas de Plex
- **Apprise** - Notificaciones multi-plataforma
- **Unpackerr** - Extractor automático de archivos
- **Organizr** - Dashboard unificado

---

## 🚀 Inicio Rápido

### 1. Configuración Inicial (10 minutos)

```bash
# Clonar y entrar al proyecto
cd /Users/ms/plexRepo

# Copiar plantilla de configuración
cp .env.example .env

# Editar configuración
nano .env
```

**Variables mínimas requeridas:**

```env
PUID=1000  # Ejecutar: id -u
PGID=1000  # Ejecutar: id -g
TZ=Chile/Continental

# Obtener en: https://www.plex.tv/claim/ (expira en 4 min)
PLEX_CLAIM=claim-xxxxxxxxxxxxxxxx

# Cambiar por seguridad
GRAFANA_ADMIN_PASSWORD=tu_password_seguro

# Rutas (ajustar según tu sistema)
PLEX_CONFIG_VOLUME=/mnt/nvme/docker-volumes/plex
TV_SERIES_VOLUME=/mnt/DiscoDuro/tvserie
MOVIES_VOLUME=/mnt/DiscoDuro/movies
DOWNLOADS_VOLUME=/mnt/DiscoDuro/downloads
```

### 2. Crear Directorios

```bash
# Configuraciones (NVMe - rápido)
sudo mkdir -p /mnt/nvme/docker-volumes/{plex,sonarr,radarr,bazarr,prowlarr,overseerr,qbittorrent}

# Medios (HDD - capacidad)
sudo mkdir -p /mnt/DiscoDuro/{tvserie,movies,downloads}

# Permisos
sudo chown -R $(id -u):$(id -g) /mnt/nvme/docker-volumes
sudo chown -R $(id -u):$(id -g) /mnt/DiscoDuro
```

### 3. Iniciar Servicios

```bash
# Validar configuración
./scripts/test-config.sh

# Iniciar servicios base
docker compose up -d

# Ver logs
docker compose logs -f
```

> **⚠️ Nota:** Usa `docker compose` (con espacio) en lugar de `docker-compose` (con guión) si tienes Docker Compose v2+

### 4. Acceder a Servicios

Espera 2-3 minutos y accede a:

- **Plex**: <http://localhost:32400/web>
- **Overseerr**: <http://localhost:5055>
- **Grafana**: <http://localhost:3000> (admin / tu_password)
- **Sonarr**: <http://localhost:8989>
- **Radarr**: <http://localhost:7878>

---

## ⚙️ Configuración Completa

### Requisitos del Sistema

- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **RAM**: Mínimo 4GB disponible
- **Disco**:
  - 50GB+ para configuraciones (NVMe recomendado)
  - 500GB+ para contenido multimedia
- **Arquitectura**: 
  - ✅ AMD64/x86_64 (Intel/AMD) - Soporte completo
  - ⚠️ ARM64 (Raspberry Pi, Apple Silicon) - Soporte parcial (algunos servicios no disponibles)

### Flujo de Trabajo

```
Usuario → Overseerr → Sonarr/Radarr → Prowlarr → Indexadores
                           ↓
                      qBittorrent (+ VPN)
                           ↓
                    Unpackerr (extrae .rar)
                           ↓
                    Bazarr (subtítulos)
                           ↓
                        Plex
                           ↓
                      Notificación (Apprise)
```

### Configuración de Servicios

#### 1. Plex

1. Accede a <http://localhost:32400/web>
2. Inicia sesión con tu cuenta de Plex
3. Agrega bibliotecas:
   - Series: `/tv`
   - Películas: `/movies`

#### 2. Prowlarr (Indexadores)

1. Accede a <http://localhost:9696>
2. Settings > Indexers > Add Indexer
3. Agrega tus indexadores favoritos
4. Settings > Apps > Add Application
   - Sonarr: <http://sonarr:8989>
   - Radarr: <http://radarr:7878>
5. Sincroniza indexadores

#### 3. Sonarr (Series)

1. Accede a <http://localhost:8989>
2. Settings > Media Management
   - Root Folder: `/tv`
3. Settings > Download Clients > Add > qBittorrent
   - Host: `qbittorrent` (o `gluetun` si usas VPN)
   - Port: `8089`

#### 4. Radarr (Películas)

1. Accede a <http://localhost:7878>
2. Configurar igual que Sonarr
   - Root Folder: `/movies`

#### 5. Overseerr (Solicitudes)

1. Accede a <http://localhost:5055>
2. Conecta con Plex
3. Conecta con Sonarr y Radarr
4. Configura permisos de usuarios

---

## 🚀 Servicios Avanzados (Opcional)

### Iniciar Servicios Avanzados

```bash
# Todos los servicios avanzados
docker compose -f docker-compose.yml -f docker-compose.advanced.yml up -d

# O solo algunos servicios específicos
docker compose -f docker-compose.yml -f docker-compose.advanced.yml up -d traefik gluetun tautulli apprise
```

### Levantar Múltiples Archivos Compose

Puedes combinar varios archivos docker-compose según tus necesidades:

```bash
# Base + Avanzados (recomendado para empezar)
docker compose -f docker-compose.yml -f docker-compose.advanced.yml up -d

# Base + Avanzados + Extras
docker compose -f docker-compose.yml -f docker-compose.advanced.yml -f docker-compose.extras.yml up -d

# TODO (base + avanzados + extras + seguridad)
docker compose -f docker-compose.yml -f docker-compose.advanced.yml -f docker-compose.extras.yml -f docker-compose.security.yml up -d
```

**Detener todos los servicios:**

```bash
# Detener base + avanzados
docker compose -f docker-compose.yml -f docker-compose.advanced.yml down

# Detener todo
docker compose -f docker-compose.yml -f docker-compose.advanced.yml -f docker-compose.extras.yml -f docker-compose.security.yml down
```

**⚠️ Notas importantes:**

1. Para usar servicios de seguridad, primero ejecuta:
   ```bash
   ./scripts/security/generate-secrets.sh
   ```

2. **Si tu servidor es ARM64** (Raspberry Pi, Oracle Cloud ARM, etc.):
   ```bash
   # Verificar arquitectura
   uname -m  # Si muestra aarch64 o arm64, usa los archivos ARM64
   
   # Usar versión compatible con ARM64
   docker compose -f docker-compose.yml -f docker-compose.advanced.yml -f docker-compose.extras-arm64.yml -f docker-compose.security-arm64.yml up -d
   ```

### 1. Traefik - SSL Automático 🔐

**Configuración:**

```env
# En .env
DOMAIN=tudominio.com
ACME_EMAIL=tu-email@ejemplo.com
```

**Acceso:**

- Dashboard: <http://localhost:8080>
- Servicios: <https://plex.tudominio.com>, <https://sonarr.tudominio.com>, etc.

### 2. Gluetun - VPN para Torrents 🔒

**Configuración:**

```env
# En .env
VPN_SERVICE_PROVIDER=nordvpn  # o tu proveedor
VPN_USERNAME=tu_usuario
VPN_PASSWORD=tu_password
VPN_SERVER_COUNTRIES=Chile
```

**Verificar VPN:**

```bash
# Ver IP pública de qBittorrent
docker exec gluetun curl ifconfig.me
```

### 3. Watchtower - Auto-actualizaciones 🔄

Actualiza contenedores automáticamente a las 4 AM diariamente.

**Personalizar horario:**

```yaml
# En docker-compose.advanced.yml
environment:
  - WATCHTOWER_SCHEDULE=0 0 4 * * *  # Formato cron
```

### 4. Tautulli - Estadísticas de Plex 📊

**Acceso:** <http://localhost:8181>

**Configurar:**

1. Settings > Plex Media Server
2. IP: `plex`, Port: `32400`
3. Obtener token de Plex

### 5. Organizr - Dashboard Unificado 🎯

**Acceso:** <http://localhost:9983>

Centraliza el acceso a todos tus servicios en un solo lugar.

---

## 📢 Notificaciones

### Configurar Apprise (5 minutos)

#### Opción 1: Discord (Recomendado)

1. Crea webhook en Discord:
   - Server Settings > Integrations > Webhooks > New Webhook
2. Edita `apprise/apprise.yml`:

```yaml
urls:
  - discord://WEBHOOK_ID/WEBHOOK_TOKEN
```

#### Opción 2: Telegram

1. Crea bot con @BotFather
2. Obtén chat_id con @userinfobot
3. Edita `apprise/apprise.yml`:

```yaml
urls:
  - tgram://BOT_TOKEN/CHAT_ID
```

#### Opción 3: Email

```yaml
urls:
  - mailto://tu-email:app-password@gmail.com
```

### Integrar con Servicios

#### Sonarr/Radarr

1. Settings > Connect > Add > Webhook
2. URL: `http://apprise:8000/notify/apprise`
3. Method: POST
4. Body:

```json
{
  "title": "📺 {EventType}",
  "body": "{Series.Title} - S{Episode.SeasonNumber}E{Episode.EpisodeNumber}\nCalidad: {EpisodeFile.Quality}"
}
```

#### Tautulli

1. Settings > Notification Agents > Webhook
2. URL: `http://apprise:8000/notify/apprise`
3. Triggers: Playback Start, Recently Added

### Probar Notificaciones

```bash
curl -X POST http://localhost:8000/notify/apprise \
  -d "title=Test" \
  -d "body=Notificaciones funcionando!"
```

---

## 🧪 Testing y Validación

### Scripts Disponibles

```bash
# Validar configuración
./scripts/test-config.sh

# Verificar healthchecks
./scripts/test-health.sh

# Probar conectividad
./scripts/test-connectivity.sh

# Crear backup
./scripts/backup.sh

# Suite completa
./scripts/run-all-tests.sh
```

### Antes de Producción

```bash
# 1. Validar
./scripts/test-config.sh

# 2. Backup
./scripts/backup.sh

# 3. Iniciar
docker compose up -d

# 4. Esperar 2 minutos
sleep 120

# 5. Verificar
./scripts/test-health.sh
./scripts/test-connectivity.sh
```

---

## 🌐 Puertos de Acceso

| Servicio | Puerto | URL | Descripción |
|----------|--------|-----|-------------|
| **Media Center** ||||
| Plex | 32400 | <http://localhost:32400/web> | Servidor multimedia |
| Overseerr | 5055 | <http://localhost:5055> | Solicitar contenido |
| Sonarr | 8989 | <http://localhost:8989> | Gestión de series |
| Radarr | 7878 | <http://localhost:7878> | Gestión de películas |
| Prowlarr | 9696 | <http://localhost:9696> | Indexadores |
| Bazarr | 6767 | <http://localhost:6767> | Subtítulos |
| qBittorrent | 8089 | <http://localhost:8089> | Cliente torrents |
| **Monitoreo** ||||
| Grafana | 3000 | <http://localhost:3000> | Dashboards |
| Prometheus | 9090 | <http://localhost:9090> | Métricas |
| cAdvisor | 8081 | <http://localhost:8081> | Métricas Docker |
| **Avanzados** ||||
| Traefik | 8080 | <http://localhost:8080> | Dashboard proxy |
| Tautulli | 8181 | <http://localhost:8181> | Estadísticas Plex |
| Apprise | 8000 | <http://localhost:8000> | Notificaciones |
| Organizr | 9983 | <http://localhost:9983> | Dashboard unificado |

---

## 🔧 Troubleshooting

### Plex no se conecta a mi cuenta

```bash
# Obtener nuevo claim token (expira en 4 min)
# Visita: https://www.plex.tv/claim/

# Actualizar .env
PLEX_CLAIM=claim-nuevo-token

# Reiniciar
docker compose restart plex
```

### Permisos denegados

```bash
# Verificar PUID/PGID
id -u  # Debe coincidir con PUID en .env
id -g  # Debe coincidir con PGID en .env

# Corregir permisos
sudo chown -R $(id -u):$(id -g) /mnt/nvme/docker-volumes
sudo chown -R $(id -u):$(id -g) /mnt/DiscoDuro
```

### Healthcheck failed

```bash
# Esperar 2 minutos (normal al inicio)
sleep 120

# Ver logs
docker compose logs <servicio>

# Reiniciar
docker compose restart <servicio>
```

### Puerto en uso

```bash
# Ver qué usa el puerto
lsof -i :32400

# Detener si es necesario
docker compose down
```

#### Conflicto común: Puerto 8080 (cAdvisor vs Traefik)

Si obtienes el error `Bind for 0.0.0.0:8080 failed: port is already allocated`:

- ✅ **Solución aplicada:** cAdvisor usa puerto 8081 (modificado en `docker-compose.yml`)
- Traefik puede usar el puerto 8080 sin conflictos
- Accede a cAdvisor en: <http://localhost:8081>

### VPN no conecta

```bash
# Ver logs
docker logs gluetun

# Verificar credenciales
cat .env | grep VPN

# Verificar IP
docker exec gluetun curl ifconfig.me
```

### Notificaciones no llegan

```bash
# Verificar Apprise
docker ps | grep apprise

# Ver logs
docker logs apprise

# Probar manualmente
curl -X POST http://localhost:8000/notify/apprise -d "body=Test"

# Verificar configuración
cat apprise/apprise.yml
```

### Error: no matching manifest for linux/arm64

Este error ocurre en sistemas ARM64 (Raspberry Pi, Oracle Cloud ARM, etc.). Algunos servicios no tienen imágenes ARM64.

**Verificar arquitectura del sistema:**

```bash
uname -m
# arm64 o aarch64 = ARM64
# x86_64 = AMD64/Intel
```

**Solución: Usar archivos compatibles con ARM64**

```bash
# Base + Avanzados (todos compatibles)
docker compose -f docker-compose.yml -f docker-compose.advanced.yml up -d

# Base + Avanzados + Extras ARM64
docker compose -f docker-compose.yml -f docker-compose.advanced.yml -f docker-compose.extras-arm64.yml up -d

# TODO: Base + Avanzados + Extras + Seguridad (versión ARM64 completa)
docker compose -f docker-compose.yml -f docker-compose.advanced.yml -f docker-compose.extras-arm64.yml -f docker-compose.security-arm64.yml up -d
```

**Servicios NO disponibles en ARM64:**
- ❌ `crowdsec` - No disponible
- ❌ `scrutiny` - No disponible
- ❌ `trivy` - No disponible
- ❌ `modsecurity` - No disponible
- ❌ `requestrr` - Soporte limitado/inestable
- ❌ `autoscan` - Soporte limitado/inestable

**Servicios SÍ disponibles en ARM64:**
- ✅ Todos los servicios base (Plex, Sonarr, Radarr, etc.)
- ✅ Todos los servicios avanzados (Traefik, Gluetun, Tautulli, etc.)
- ✅ Todos los servicios extras (Kometa, Homepage, Recyclarr, etc.)
- ✅ Servicios de seguridad: Authelia, Fail2ban, ClamAV, Loki, Promtail

**Archivos ARM64 creados:**
- `docker-compose.extras-arm64.yml` - Servicios extras sin Scrutiny
- `docker-compose.security-arm64.yml` - Servicios de seguridad compatibles

---

## 📝 Comandos Útiles

### Comandos Básicos

```bash
# Iniciar servicios base
docker compose up -d

# Iniciar con servicios avanzados
docker compose -f docker-compose.yml -f docker-compose.advanced.yml up -d

# Iniciar TODO (base + avanzados + extras)
docker compose -f docker-compose.yml -f docker-compose.advanced.yml -f docker-compose.extras.yml up -d

# Ver logs en tiempo real
docker compose logs -f

# Ver logs de un servicio específico
docker compose logs -f plex

# Ver estado
docker compose ps

# Reiniciar servicio
docker compose restart <servicio>

# Detener todo
docker compose down

# Detener servicios avanzados
docker compose -f docker-compose.yml -f docker-compose.advanced.yml down

# Actualizar imágenes
docker compose pull
docker compose up -d

# Ver uso de recursos
docker stats

# Limpiar contenedores e imágenes no usadas
docker system prune -a
```

### Aliases Recomendados

Agrega estos aliases a tu `~/.bashrc` o `~/.zshrc` para facilitar el uso:

```bash
# Agregar al final del archivo
alias dc='docker compose'
alias dc-up='docker compose up -d'
alias dc-down='docker compose down'
alias dc-logs='docker compose logs -f'
alias dc-ps='docker compose ps'

# Para servicios avanzados
alias dc-all-up='docker compose -f docker-compose.yml -f docker-compose.advanced.yml -f docker-compose.extras.yml up -d'
alias dc-all-down='docker compose -f docker-compose.yml -f docker-compose.advanced.yml -f docker-compose.extras.yml down'
alias dc-all-logs='docker compose -f docker-compose.yml -f docker-compose.advanced.yml -f docker-compose.extras.yml logs -f'
```

**Aplicar cambios:**

```bash
source ~/.bashrc  # o source ~/.zshrc
```

**Uso después de configurar aliases:**

```bash
dc-up              # Iniciar servicios base
dc-all-up          # Iniciar todos los servicios
dc-logs plex       # Ver logs de Plex
dc-ps              # Ver estado
dc-all-down        # Detener todo
```

---

## 🔒 Seguridad

### Seguridad Base

- ✅ Archivo `.env` excluido de Git
- ✅ Credenciales en variables de entorno
- ✅ Redes Docker aisladas
- ✅ Healthchecks automáticos
- ✅ Límites de recursos
- ✅ Logging controlado (30MB máx por contenedor)
- ✅ VPN para torrents (opcional)
- ✅ SSL automático con Traefik (opcional)

### Seguridad Avanzada (Opcional)

Sistema de seguridad completo disponible en `docker-compose.security.yml`:

**Autenticación y Acceso:**

- **Authelia** - SSO con 2FA (Google Authenticator)
- **Fail2ban** - Anti fuerza bruta

**Protección:**

- **ClamAV** - Antivirus para descargas
- **ModSecurity** - Web Application Firewall
- **CrowdSec** - Detección de intrusiones

**Monitoreo:**

- **Loki + Promtail** - Logs centralizados
- **Trivy** - Escaneo de vulnerabilidades

**Datos:**

- **Docker Secrets** - Gestión segura de credenciales
- **Backups Encriptados** - AES-256

**Iniciar servicios de seguridad:**

```bash
# Generar secrets
./scripts/security/generate-secrets.sh

# Iniciar servicios de seguridad
docker compose -f docker-compose.yml -f docker-compose.security.yml up -d

# Configurar 2FA
# Accede a: http://localhost:9091
```

**Documentación completa:** Ver `SECURITY.md`

---

## 📚 Documentación

- **GUIA_PRINCIPIANTES.md** ⭐ - Paso a paso desde cero (instalación, configuración, uso)
- **SECURITY.md** - Guía completa de seguridad (2FA, antivirus, backups, etc.)
- **EXTRAS_GUIDE.md** - Servicios extras (Recyclarr, Uptime Kuma, Requestrr, etc.)

---

## 🎯 Próximos Pasos

1. ✅ Configurar servicios base
2. ✅ Agregar bibliotecas en Plex
3. ✅ Conectar Prowlarr con Sonarr/Radarr
4. ✅ Configurar indexadores
5. ✅ Configurar notificaciones (Apprise)
6. ✅ Habilitar VPN (Gluetun) si lo deseas
7. ✅ Configurar SSL (Traefik) para acceso externo
8. ✅ Monitorear en Grafana

---

## 📊 Características

### Seguridad

- Variables de entorno protegidas
- Redes aisladas
- VPN opcional para torrents
- SSL automático

### Automatización

- Descarga automática de contenido
- Extracción automática de archivos
- Actualización automática de contenedores
- Subtítulos automáticos

### Monitoreo

- Métricas en tiempo real
- Dashboards de Grafana
- Healthchecks automáticos
- Notificaciones inteligentes

### Usabilidad

- Interfaz web para todo
- Dashboard unificado
- Solicitudes de usuarios
- Estadísticas detalladas

---

**Versión:** 2.3.0  
**Última actualización:** 26 de Octubre, 2025  
**Mantenido por:** IgriegaL/plexRepo

**Cambios en v2.3.0:**
- ✅ Actualizado a Docker Compose v2 (sintaxis moderna)
- ✅ Corregido conflicto de puerto 8080 (cAdvisor → 8081)
- ✅ Agregados comandos para levantar múltiples archivos compose
- ✅ Agregados aliases recomendados para facilitar el uso
- ✅ Soporte completo para ARM64 (aarch64)
- ✅ Nuevos archivos ARM64: `docker-compose.extras-arm64.yml` y `docker-compose.security-arm64.yml`
- ✅ Documentación de compatibilidad de arquitecturas

**¿Necesitas ayuda?** Revisa la sección de [Troubleshooting](#-troubleshooting) o consulta los scripts de testing.
