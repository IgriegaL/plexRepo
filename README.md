# 🍊 Plex Media Server

Stack completo de media server con Docker Compose, pensado para **Orange Pi 5 Pro (RK3588)** y probado también en **Linux** (Ubuntu) y **macOS** (Apple Silicon).

Un solo comando instala Docker si hace falta, levanta todos los servicios y **los conecta entre sí automáticamente**: no hay que copiar API keys ni configurar clientes de descarga a mano.

```bash
git clone https://github.com/IgriegaL/plexRepo.git
cd plexRepo
./scripts/setup.sh
```

---

## 📑 Índice

1. [Qué incluye](#-qué-incluye)
2. [Requisitos](#-requisitos)
3. [Instalación](#-instalación)
4. [Qué hace la automatización](#-qué-hace-la-automatización)
5. [Qué debes hacer tú](#-qué-debes-hacer-tú)
6. [Endpoints expuestos](#-endpoints-expuestos)
7. [Uso diario](#-uso-diario)
8. [Configuración (.env)](#-configuración-env)
9. [Linux vs macOS](#-linux-vs-macos)
10. [Solución de problemas](#-solución-de-problemas)
11. [Recursos y estabilidad](#-recursos-y-estabilidad)
12. [Seguridad](#-seguridad)
13. [Estructura del repositorio](#-estructura-del-repositorio)

---

## 🚀 Qué incluye

| Categoría | Servicios |
| :--- | :--- |
| **Media** | Plex (transcodificación por hardware si hay GPU), Tautulli |
| **Automatización de descargas** | Sonarr (series), Radarr (películas), Prowlarr (indexers), Bazarr (subtítulos), qBittorrent, FlareSolverr |
| **Peticiones** | Overseerr (web), Requestrr (Discord) |
| **Acceso** | Caddy (reverse proxy con nombres amigables) |
| **Administración** | Portainer (UI de Docker), Dozzle (logs en vivo), Netdata (monitoreo) |
| **Auto-configuración** | `init` y `bootstrap`: contenedores que corren una vez y dejan todo conectado |

### Cómo fluye el contenido

```
 Overseerr ──pide──▶ Sonarr / Radarr ──busca en──▶ Prowlarr ──▶ indexers (vía FlareSolverr si hay Cloudflare)
                          │
                          ├──envía torrent──▶ qBittorrent ──descarga──▶ /data/downloads
                          │
                          ├──importa/renombra (hardlink)──▶ /data/tvserie  ·  /data/movies
                          │
                          └──avisa──▶ Plex (refresca la biblioteca) ──▶ Tautulli (estadísticas)

 Bazarr ──lee series/películas de Sonarr/Radarr──▶ descarga subtítulos
```

---

## 📋 Requisitos

| | Linux | macOS |
| :--- | :--- | :--- |
| **Sistema** | Cualquier distro con systemd (Ubuntu, Debian, Armbian…) | macOS 13+ (Apple Silicon o Intel) |
| **Docker** | Lo instala `setup.sh` (script oficial `get.docker.com`) | Lo instala `setup.sh`: [Colima](https://github.com/abiosoft/colima) + Docker CLI + Compose vía Homebrew (gratis y open source) |
| **Otros** | `curl`, `sudo` | [Homebrew](https://brew.sh) |
| **RAM** | 4 GB mínimo, 8 GB recomendado | 16 GB recomendado (Colima usa 8 GB) |
| **Disco** | NVMe/SSD para configs + HDD para medios (recomendado) | ~15 GB libres para imágenes |

Además necesitas una **cuenta de Plex** (gratis) para vincular el servidor.

---

## 🛠️ Instalación

### 1. Clona y ejecuta

```bash
git clone https://github.com/IgriegaL/plexRepo.git
cd plexRepo
./scripts/setup.sh
```

### 2. Pega el código de Plex cuando lo pida

Si Plex aún no está vinculado a tu cuenta, el script se detiene y pide un código:

```
Plex aún no está vinculado a tu cuenta.
Abre https://www.plex.tv/claim/ y pega el código (Enter para omitir):
```

Abre [plex.tv/claim](https://www.plex.tv/claim/), inicia sesión y copia el código `claim-xxxx`. **Expira en 4 minutos**, así que pégalo de inmediato. También puedes pasarlo directamente:

```bash
./scripts/setup.sh --claim claim-xxxxxxxxxxxxxxxx
```

### 3. Espera el resumen

La primera vez tarda unos minutos (descarga ~5 GB de imágenes). Al final verás algo así:

```
[BOOTSTRAP] Sonarr: login configurado (usuario 'admin')
[BOOTSTRAP] Sonarr: carpeta raíz /data/tvserie agregada
[BOOTSTRAP] Sonarr: qBittorrent agregado (downloadclient)
...
[BOOTSTRAP] Overseerr: asistente inicial completado
[BOOTSTRAP] ✅ Todo configurado

================================================================
 Usuario: admin   Contraseña: (ADMIN_PASSWORD en .env)

 Overseerr    http://192.168.1.50:5055   (entra con tu cuenta de Plex)
 ...
```

La contraseña está en el archivo `.env`:

```bash
grep ADMIN_PASSWORD .env
```

### Qué hace `setup.sh` paso a paso

| Paso | Linux | macOS |
| :--- | :--- | :--- |
| 0. Docker | Lo instala si falta y lo habilita al arranque (`systemctl enable docker`) | Instala Colima si falta y la inicia con la mitad de CPU/RAM (máx. 8 GB) |
| 1. `.env` | Lo crea desde `.env.example`: `PUID`/`PGID` de tu usuario y `ADMIN_PASSWORD` aleatoria | Igual |
| 2. Rutas | Usa `/mnt/nvme` y `/mnt/DiscoDuro` si existen; si no, `~/plex-stack/` | Siempre `~/plex-stack/` |
| 3. GPU | Si existe `/dev/dri`, activa la transcodificación por hardware de Plex | Sin GPU: agrega `docker-compose.no-gpu.yml` |
| 4. Carpetas | Crea las carpetas de config y medios con el dueño correcto | Igual |
| 5. Plex | Pide el claim solo si Plex no está vinculado | Igual |
| 6. Arranque | `docker compose pull` + `up -d` y muestra el log de `bootstrap` | Igual |

Ejecutar `setup.sh` otra vez es seguro: no sobrescribe tu `.env` ni duplica configuraciones.

---

## 🤖 Qué hace la automatización

Hay dos contenedores que corren una vez y terminan. Los dos son **idempotentes**: se ejecutan en cada `docker compose up -d` y solo agregan lo que falta.

### `init` (antes de qBittorrent)

Prepara `qBittorrent.conf` para evitar la contraseña temporal que qBittorrent muestra en los logs:

- Usuario y contraseña de la WebUI = `ADMIN_USER` / `ADMIN_PASSWORD` (hash PBKDF2)
- Descargas en `/data/downloads/`, incompletas en `/data/downloads/incomplete/`
- Acepta el aviso legal y desactiva la validación de host (para entrar vía Caddy)

Si qBittorrent ya tiene contraseña, **no la cambia**.

### `bootstrap` (después de levantar todo)

Lee la API key de cada app desde sus propios archivos de configuración (`config.xml`, `config.yaml`, `settings.json`, `Preferences.xml`). Por eso **nunca tienes que copiar API keys**. Luego configura:

| Servicio | Qué configura |
| :--- | :--- |
| **Sonarr** | Login (formulario, usuario `admin`) · carpeta raíz `/data/tvserie` · qBittorrent (categoría `tv-sonarr`) · notificación a Plex para refrescar la biblioteca al importar |
| **Radarr** | Login · carpeta raíz `/data/movies` · qBittorrent (categoría `radarr`) · notificación a Plex |
| **Prowlarr** | Login · FlareSolverr como proxy (etiqueta `flaresolverr`) · sincronización completa con Sonarr y Radarr |
| **Bazarr** | Conexión con Sonarr y Radarr |
| **Plex** | Bibliotecas **Películas** (`/data/movies`) y **Series** (`/data/tvserie`) |
| **Overseerr** | Inicia sesión con la cuenta dueña de Plex (queda como admin) · conecta Plex y habilita bibliotecas · agrega Sonarr y Radarr con el perfil `QUALITY_PROFILE` · completa el asistente inicial |

Si algún paso falla, el resto sigue y al final muestra un resumen de advertencias. En ese caso el contenedor termina con código 1.

---

## ✋ Qué debes hacer tú

La automatización no puede hacer lo que depende de tus cuentas o tus preferencias:

| # | Tarea | Dónde | Obligatorio |
| :-: | :--- | :--- | :-: |
| 1 | Pegar el **código de claim de Plex** (solo la primera vez) | `setup.sh` | ✅ |
| 2 | **Agregar indexers** (torrent trackers). Para sitios con Cloudflare, ponles la etiqueta `flaresolverr` | Prowlarr → Indexers → Add | ✅ |
| 3 | Elegir **idiomas y proveedores de subtítulos** | Bazarr → Settings → Languages / Providers | Opcional |
| 4 | Completar el **asistente de Tautulli** (iniciar sesión con Plex) | `http://IP:8181` | Opcional |
| 5 | Configurar el **bot de Discord** | Requestrr `http://IP:4545` | Opcional |
| 6 | Ajustar el **perfil de calidad** si no quieres 1080p | `.env` → `QUALITY_PROFILE`, o en Overseerr | Opcional |
| 7 | Usar **nombres amigables** (`sonarr.plex-server`): apunta `*.plex-server` a la IP del servidor en tu DNS o en `/etc/hosts` | Tu router / equipo | Opcional |

Después de eso, el uso normal es: **pide una película o serie en Overseerr** y el resto pasa solo. Se busca, se descarga, se renombra, aparece en Plex y se bajan los subtítulos.

---

## 🌐 Endpoints expuestos

Todos los puertos se publican en todas las interfaces del servidor (`0.0.0.0`). Reemplaza `IP` por la IP del servidor (o `localhost` si estás en la misma máquina).

### Interfaces web

| Servicio | URL directa | Vía Caddy (`:8080`) | Login |
| :--- | :--- | :--- | :--- |
| **Overseerr** | `http://IP:5055` | `http://IP:8080` · `http://overseerr.plex-server:8080` | Cuenta de Plex |
| **Plex** | `http://IP:32400/web` | `http://plex.plex-server:8080` | Cuenta de Plex |
| **Sonarr** | `http://IP:8989` | `http://sonarr.plex-server:8080` | `admin` / `ADMIN_PASSWORD` |
| **Radarr** | `http://IP:7878` | `http://radarr.plex-server:8080` | `admin` / `ADMIN_PASSWORD` |
| **Prowlarr** | `http://IP:9696` | `http://prowlarr.plex-server:8080` | `admin` / `ADMIN_PASSWORD` |
| **qBittorrent** | `http://IP:8089` | `http://qbittorrent.plex-server:8080` | `admin` / `ADMIN_PASSWORD` |
| **Bazarr** | `http://IP:6767` | `http://bazarr.plex-server:8080` | Sin login (configurable) |
| **Tautulli** | `http://IP:8181` | `http://tautulli.plex-server:8080` | Asistente inicial |
| **Requestrr** | `http://IP:4545` | — | Se crea en el primer acceso |
| **Portainer** | `http://IP:9000` | `http://portainer.plex-server:8080` | Se crea en el primer acceso (**hazlo pronto**, ver [Seguridad](#-seguridad)) |
| **Dozzle** | `http://IP:8888` | `http://dozzle.plex-server:8080` | Sin login |
| **Netdata** | `http://IP:19999` | `http://netdata.plex-server:8080` | Sin login |
| **FlareSolverr** | `http://IP:8191` | `http://flaresolverr.plex-server:8080` | API sin UI |

### Otros puertos

| Puerto | Protocolo | Uso |
| :--- | :--- | :--- |
| `32400` | TCP | Plex (corre en `network_mode: host`, así que usa también los puertos de descubrimiento de Plex en la LAN) |
| `6881` | TCP/UDP | Puerto de torrents de qBittorrent (ábrelo en el router para mejor velocidad) |
| `8443` | TCP | Caddy HTTPS (sin uso por defecto) |

### APIs (para scripts o integraciones)

Todas usan la API key que cada app guarda en su configuración. Es la misma que lee `bootstrap`.

| Servicio | Base | Autenticación |
| :--- | :--- | :--- |
| Sonarr | `http://IP:8989/api/v3` | Header `X-Api-Key` (en `SONARR_CONFIG_VOLUME/config.xml`) |
| Radarr | `http://IP:7878/api/v3` | Header `X-Api-Key` (en `RADARR_CONFIG_VOLUME/config.xml`) |
| Prowlarr | `http://IP:9696/api/v1` | Header `X-Api-Key` (en `PROWLARR_CONFIG_VOLUME/config.xml`) |
| Overseerr | `http://IP:5055/api/v1` | Header `X-Api-Key` (en `OVERSEERR_CONFIG_VOLUME/settings.json`) |
| Bazarr | `http://IP:6767/api` | Header `X-API-KEY` (en `BAZARR_CONFIG_VOLUME/config/config.yaml`) |
| qBittorrent | `http://IP:8089/api/v2` | Cookie de `POST /api/v2/auth/login` |
| Plex | `http://IP:32400` | Header `X-Plex-Token` (`PlexOnlineToken` en `Preferences.xml`) |

Ejemplo:

```bash
KEY=$(sed -n 's:.*<ApiKey>\(.*\)</ApiKey>.*:\1:p' ~/plex-stack/config/sonarr/config.xml)
curl -H "X-Api-Key: $KEY" http://localhost:8989/api/v3/series
```

---

## 🔁 Uso diario

```bash
./scripts/setup.sh                    # instalar / reparar / aplicar cambios del .env
docker compose ps                     # estado de los servicios
docker logs -f bootstrap              # qué hizo la auto-configuración
docker compose run --rm bootstrap     # volver a ejecutar la auto-configuración
docker compose logs -f sonarr         # logs de un servicio (o usa Dozzle)
docker compose restart radarr         # reiniciar un servicio
docker compose pull && docker compose up -d   # actualizar todas las imágenes
docker compose down                   # detener todo (los datos se conservan)
./scripts/monitor.sh                  # RAM, swap, temperatura y top de contenedores
./scripts/backup.sh                   # respaldo de configs en ~/plex-backups
```

> `docker compose` lee `COMPOSE_FILE` desde `.env`, así que estos comandos aplican solos el override sin GPU cuando corresponde. En Linux, si tu usuario no está en el grupo `docker`, anteponles `sudo`.

**Arranque automático:** todos los servicios tienen `restart: unless-stopped`.
- **Linux:** Docker queda habilitado al iniciar el sistema, así que el stack vuelve solo tras un reinicio.
- **macOS:** Colima no arranca sola al iniciar sesión. Para activarlo: `colima stop && brew services start colima`.

---

## ⚙️ Configuración (`.env`)

`setup.sh` crea el `.env` a partir de [`.env.example`](.env.example). Después de editarlo, ejecuta `./scripts/setup.sh` otra vez.

| Variable | Por defecto | Descripción |
| :--- | :--- | :--- |
| `PUID` / `PGID` | Tu usuario | Dueño de los archivos que crean los contenedores |
| `TZ` | `America/Santiago` | Zona horaria |
| `ADMIN_USER` | `admin` | Usuario de qBittorrent, Sonarr, Radarr y Prowlarr |
| `ADMIN_PASSWORD` | Aleatoria | Contraseña de esos servicios |
| `PLEX_CLAIM` | — | Código de [plex.tv/claim](https://www.plex.tv/claim/), solo para el primer arranque |
| `QUALITY_PROFILE` | `HD-1080p` | Perfil que Overseerr usa por defecto en Sonarr/Radarr |
| `PLEX_LANGUAGE` | `es-ES` | Idioma de metadatos de las bibliotecas creadas |
| `*_CONFIG_VOLUME` | `/mnt/nvme/docker-volumes/<app>` o `~/plex-stack/config/<app>` | Configuración de cada app (mejor en SSD) |
| `MEDIA_VOLUME` | `/mnt/DiscoDuro` o `~/plex-stack/media` | Medios y descargas (`movies/`, `tvserie/`, `downloads/`), montado como `/data` en todos los servicios para que las importaciones sean hardlinks y no copias |
| `COMPOSE_FILE` | Lo define `setup.sh` | Agrega `docker-compose.no-gpu.yml` si no hay `/dev/dri` |
| `NETDATA_CLAIM_TOKEN` | — | Opcional, para vincular Netdata Cloud |

---

## 🐧🍎 Linux vs macOS

| | Linux | macOS |
| :--- | :--- | :--- |
| Motor de Docker | Docker Engine nativo | VM Linux de Colima (Docker Desktop/OrbStack también se aceptan si ya están corriendo, pero no se han probado) |
| Transcodificación por hardware | Sí, si existe `/dev/dri` (Orange Pi, Intel iGPU…) | No, se usa la CPU |
| `network_mode: host` de Plex | Red del host | Red de la VM; Colima reenvía el puerto 32400 a la Mac |
| Netdata / `monitor.sh` | Miden el host | Miden la VM de Colima |
| `setup-swap.sh` | Crea `/swapfile` | No aplica (la RAM la define Colima: `colima start --memory N`) |

Probado de punta a punta en **macOS 27 (Apple Silicon) + Colima 0.10** y en **Ubuntu 26.04 ARM64** sin Docker preinstalado.

---

## 🩺 Solución de problemas

| Síntoma | Causa / solución |
| :--- | :--- |
| `Plex no está reclamado` al final del bootstrap | No se pegó el claim o expiró. Obtén otro en [plex.tv/claim](https://www.plex.tv/claim/) y ejecuta `./scripts/setup.sh --claim claim-xxxx`, luego `docker compose run --rm bootstrap` |
| Sonarr/Radarr no pueden conectar con qBittorrent | Instalación previa con otra contraseña en qBittorrent. Pon esa misma contraseña en `ADMIN_PASSWORD` y vuelve a ejecutar `docker compose run --rm bootstrap` |
| `bootstrap` sale con código 1 | Revisa `docker logs bootstrap`: al final lista cada advertencia. Corrige y vuelve a ejecutarlo |
| No veo resultados al buscar | Falta agregar indexers en Prowlarr (paso 2 de [Qué debes hacer tú](#-qué-debes-hacer-tú)) |
| Un indexer falla por Cloudflare | Agrégale la etiqueta `flaresolverr` en Prowlarr |
| `*.plex-server:8080` no abre | Falta apuntar el nombre a la IP del servidor (DNS o `/etc/hosts`) |
| macOS: `Cannot connect to the Docker daemon` | Colima está detenida: `colima start` (o ejecuta `./scripts/setup.sh`) |
| Linux: `permission denied ... docker.sock` | Usa `sudo docker compose ...` o agrega tu usuario al grupo: `sudo usermod -aG docker $USER` y vuelve a iniciar sesión |
| El sistema se cuelga por falta de memoria | `sudo ./scripts/setup-swap.sh` (Linux) y revisa `./scripts/monitor.sh` |

---

## ⚙️ Recursos y estabilidad

Cada servicio tiene límites de `mem_limit` / `cpus` en `docker-compose.yml`, pensados para una Orange Pi 5 Pro de 8 GB. Plex tiene la mayor parte (2 GB / 2 CPU).

1. **Swap (recomendado en la Pi):** `sudo ./scripts/setup-swap.sh`
2. **Monitoreo:** `./scripts/monitor.sh` o Netdata en `:19999` (ver [MONITORING.md](MONITORING.md))
3. **Menos carga de transcodificación** en Plex:
   - Configura los clientes en "Calidad máxima" para que reproduzcan directo (Direct Play)
   - Limita "Maximum simultaneous video transcode" a 1–2
   - Si hay crashes, desactiva "Use hardware acceleration"

---

## 🔒 Seguridad

- **No abras estos puertos a Internet.** Para acceso remoto usa una VPN en el host, como Tailscale o WireGuard (no incluida en el stack).
- **Portainer, Dozzle y Netdata tienen acceso a `docker.sock`**, que equivale a acceso root al host. Crea el usuario de Portainer apenas levantes el stack y no expongas Dozzle ni Netdata fuera de tu red.
- Sonarr, Radarr, Prowlarr y qBittorrent piden login siempre. Las credenciales están en `.env`, que no se sube a git (está en `.gitignore`).
- Para cambiar la contraseña después de instalar, hazlo en la UI de cada servicio. `bootstrap` no sobrescribe un login que ya existe.

---

## 📁 Estructura del repositorio

```
.
├── docker-compose.yml          # Definición de todos los servicios
├── docker-compose.no-gpu.yml   # Override sin /dev/dri (macOS, VMs, Linux sin GPU)
├── .env.example                # Plantilla de configuración
├── Caddyfile                   # Reverse proxy *.plex-server:8080
├── netdata.conf                # Retención y alertas de Netdata
├── bootstrap/
│   └── bootstrap.py            # Auto-configuración (init + configure), solo librería estándar de Python
├── scripts/
│   ├── setup.sh                # Instalación/arranque en un paso (Linux y macOS)
│   ├── monitor.sh              # Estado de recursos y contenedores
│   ├── backup.sh               # Respaldo de configuraciones
│   └── setup-swap.sh           # Swap en Linux
└── .github/workflows/          # Validación de compose, scripts y seguridad
```
