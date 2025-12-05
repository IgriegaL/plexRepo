# 🍊 Plex Media Server 

Stack completo de servidor de medios optimizado para **Orange Pi 5 Pro (RK3588)** usando Docker Compose.

## 🚀 Características

*   **Media Center:** Plex (con transcodificación por hardware), Sonarr, Radarr, Bazarr, Prowlarr, Overseerr, qBittorrent.
*   **Gestión:** Portainer (UI Docker), Watchtower (Actualizaciones automáticas), Dozzle (Logs en tiempo real).
*   **Red:** Gluetun (VPN para descargas seguras).
*   **Automatización:** Script `bootstrap` para autoconfigurar conexiones entre servicios.

## 📋 Requisitos

*   **Hardware:** Orange Pi 5 Pro (o similar con RK3588).
*   **Almacenamiento:**
    *   NVMe SSD (Recomendado para configs/bases de datos).
    *   HDD (Para almacenamiento de medios).
*   **Software:** Docker y Docker Compose instalados.

## 🛠️ Instalación Rápida

1.  **Clonar repositorio:**
    ```bash
    git clone <tu-repo>
    cd plexRepo
    ```

2.  **Configurar entorno:**
    ```bash
    cp .env.example .env
    nano .env
    ```
    *Rellena las rutas de tus discos y, opcionalmente, tus credenciales de VPN.*

3.  **Crear directorios:**
    ```bash
    # Ajusta las rutas según tu .env
    sudo mkdir -p /mnt/nvme/docker-volumes/{plex,sonarr,radarr,bazarr,prowlarr,overseerr,qbittorrent,portainer,gluetun}
    sudo mkdir -p /mnt/DiscoDuro/{tvserie,movies,downloads}
    sudo chown -R 1000:1000 /mnt/nvme/docker-volumes /mnt/DiscoDuro
    ```

4.  **Iniciar:**
    ```bash
    docker compose up -d
    ```

## 🤖 Autoconfiguración (Bootstrap)

El servicio `bootstrap` se ejecuta al inicio e intenta conectar tus aplicaciones automáticamente.

1.  La primera vez que inicies, entra a Sonarr, Radarr y Prowlarr para obtener sus **API Keys**.
2.  Añádelas a tu archivo `.env`.
3.  Reinicia el stack: `docker compose up -d`.
4.  El script configurará automáticamente:
    *   Sonarr/Radarr → qBittorrent
    *   Prowlarr → Sonarr/Radarr

## 🌐 Puertos Principales

| Servicio | Puerto | Descripción |
| :--- | :--- | :--- |
| **Plex** | `32400` | Servidor de Medios |
| **Overseerr** | `5055` | Solicitud de contenido |
| **Portainer** | `9000` | Gestión de Docker |
| **Dozzle** | `8080` | Visor de Logs |
| **Sonarr** | `8989` | Series de TV |
| **Radarr** | `7878` | Películas |
| **qBittorrent** | `8089` | Cliente Torrent |

## 🔒 VPN (Opcional)

Para enrutar qBittorrent por VPN:
1.  Configura `VPN_SERVICE_PROVIDER`, `VPN_USER` y `VPN_PASSWORD` en `.env`.
2.  En `docker-compose.yml`, descomenta la configuración de red en el servicio `qbittorrent` para usar `service:gluetun`.

## 🔄 Mantenimiento

*   **Actualizaciones:** Watchtower actualiza los contenedores automáticamente cada día a las 4 AM.
*   **Backups:** Ejecuta `./scripts/backup.sh` para respaldar tus configuraciones.
