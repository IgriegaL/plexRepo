# 🍊 Plex Media Server

Complete media server stack optimized for **Orange Pi 5 Pro (RK3588)** using Docker Compose.

## 🚀 Features

*   **Media Center:** Plex (with hardware transcoding), Sonarr, Radarr, Bazarr, Prowlarr, Overseerr, qBittorrent.
*   **Photos/Videos:** Immich (Self-hosted photo/video management).
*   **Management:** Portainer (Docker UI), Watchtower (Automatic updates), Dozzle (Real-time logs).
*   **Networking:** Gluetun (VPN for secure downloads).
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
    *Fill in your disk paths and, optionally, your VPN credentials.*

3.  **Create directories:**
    ```bash
    # Adjust paths according to your .env
    sudo mkdir -p /mnt/nvme/docker-volumes/{plex,sonarr,radarr,bazarr,prowlarr,overseerr,qbittorrent,portainer,gluetun,immich-postgres}
    sudo mkdir -p /mnt/DiscoDuro/{tvserie,movies,downloads,immich/uploads}
    sudo chown -R 1000:1000 /mnt/nvme/docker-volumes /mnt/DiscoDuro
    ```

4.  **Start:**
    ```bash
    docker compose up -d
    ```

## 🤖 Auto-Configuration (Bootstrap)

The `bootstrap` service runs at startup and automatically attempts to connect your applications.

1.  The first time you start, access Sonarr, Radarr, and Prowlarr to obtain their **API Keys**.
2.  Add them to your `.env` file.
3.  Restart the stack: `docker compose up -d`.
4.  The script will automatically configure:
    *   Sonarr/Radarr → qBittorrent
    *   Prowlarr → Sonarr/Radarr

## 🌐 Main Ports

| Service | Port | Description |
| :--- | :--- | :--- |
| **Plex** | `32400` | Media Server |
| **Immich** | `2283` | Photo/Video Management |
| **Overseerr** | `5055` | Content Request |
| **Portainer** | `9000` | Docker Management |
| **Dozzle** | `8080` | Logs Viewer |
| **Sonarr** | `8989` | TV Series |
| **Radarr** | `7878` | Movies |
| **qBittorrent** | `8089` | Torrent Client |

## 🔒 VPN (Optional)

To route qBittorrent through VPN:
1.  Configure `VPN_SERVICE_PROVIDER`, `VPN_USER`, and `VPN_PASSWORD` in `.env`.
2.  In `docker-compose.yml`, uncomment the network configuration in the `qbittorrent` service to use `service:gluetun`.

## 🔄 Maintenance

*   **Updates:** Watchtower automatically updates containers every day at 4 AM.
*   **Backups:** Run `./scripts/backup.sh` to backup your configurations.
