# 🍊 Plex Media Server

Complete media server stack optimized for **Orange Pi 5 Pro (RK3588)** using Docker Compose.

## 🚀 Features

*   **Media Center:** Plex (Hardware Transcoding), Sonarr, Radarr, Bazarr, Prowlarr, Overseerr, qBittorrent, Tautulli.
*   **Photos/Videos:** Immich (Self-hosted photo/video management).
*   **Utilities:** Unpackerr (Auto-extract), Flaresolverr (Cloudflare solver).
*   **Access & Security:** Caddy (Reverse Proxy), Tailscale (Secure Remote Access).
*   **Management:** Portainer (Docker UI), Dozzle (Real-time logs).
*   **Automation:** `bootstrap` script for auto-configuring connections between services.

## 📋 Requirements

*   **Hardware:** Orange Pi 5 Pro (or similar with RK3588).
*   **Storage:**
    *   NVMe SSD (Recommended for configs/databases).
    *   HDD (For media storage).
*   **Software:** Docker and Docker Compose installed.

## 🛠️ Quick Installation

1.  **Clone repository:**
    ```bash
    git clone <your-repo>
    cd plexRepo
    ```

2.  **Configure environment:**
    ```bash
    cp .env.example .env
    nano .env
    ```
    *Fill in your disk paths, API Keys, and Tailscale Auth Key.*

3.  **Create directories:**
    ```bash
    # Adjust paths according to your .env
    sudo mkdir -p /mnt/nvme/docker-volumes/{plex,sonarr,radarr,bazarr,prowlarr,overseerr,qbittorrent,portainer,gluetun,immich-postgres,tautulli,tailscale,npm-data,npm-letsencrypt}
    sudo mkdir -p /mnt/DiscoDuro/{tvserie,movies,downloads,immich/uploads}
    sudo chown -R 1000:1000 /mnt/nvme/docker-volumes /mnt/DiscoDuro
    ```

4.  **Start:**
    ```bash
    docker compose up -d
    ```

## 🌐 Access (via Tailscale & Caddy)

Once connected to your Tailscale network, you can access services using friendly names.
*Default hostname:* `plex-server` (You can change this in `docker-compose.yml` and `Caddyfile`).

| Service | URL | Description |
| :--- | :--- | :--- |
| **Overseerr** | `http://plex-server` | Request Content (Home) |
| **Plex** | `http://plex.plex-server` | Media Server |
| **Immich** | `http://immich.plex-server` | Photos & Videos |
| **Sonarr** | `http://sonarr.plex-server` | TV Series |
| **Radarr** | `http://radarr.plex-server` | Movies |
| **Tautulli** | `http://tautulli.plex-server` | Plex Statistics |
| **Portainer** | `http://portainer.plex-server` | Docker Management |

*Note: You can still access via IP:Port if needed.*

## 🤖 Auto-Configuration (Bootstrap)

The `bootstrap` service runs at startup and automatically attempts to connect your applications.

1.  The first time you start, access Sonarr, Radarr, and Prowlarr to obtain their **API Keys**.
2.  Add them to your `.env` file.
3.  Restart the stack: `docker compose up -d`.
4.  The script will automatically configure:
    *   Sonarr/Radarr → qBittorrent (with "Remove Completed" enabled)
    *   Prowlarr → Sonarr/Radarr

## ⚙️ Resource Management

Containers are configured with CPU and RAM limits to ensure stability on the Orange Pi 5 Pro:
*   **Plex:** 4GB RAM / 6 CPUs
*   **Immich:** 2GB RAM / 2 CPUs
*   **Others:** Optimized for low footprint.

## 🔒 Remote Access

*   **Tailscale:** Included for secure remote access without opening ports.
*   **Direct Play:** Configure Plex clients to "Maximum Quality" to avoid transcoding over the VPN.

## 🔄 Maintenance

*   **Backups:** Run `./scripts/backup.sh` to backup your configurations.
