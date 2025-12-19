# 🍊 Plex Media Server

Complete media server stack optimized for **Orange Pi 5 Pro (RK3588)** using Docker Compose.

## 🚀 Features

*   **Media Center:** Plex (Hardware Transcoding), Sonarr, Radarr, Bazarr, Prowlarr, Overseerr, qBittorrent, Tautulli.
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
    sudo mkdir -p /mnt/nvme/docker-volumes/{plex,sonarr,radarr,bazarr,prowlarr,overseerr,qbittorrent,portainer,gluetun,tautulli,tailscale,npm-data,npm-letsencrypt}
    sudo mkdir -p /mnt/DiscoDuro/{tvserie,movies,downloads}
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
| **Overseerr** | `http://plex-server:8080` | Request Content (Home) |
| **Plex** | `http://plex.plex-server:8080` | Media Server |
| **Sonarr** | `http://sonarr.plex-server:8080` | TV Series |
| **Radarr** | `http://radarr.plex-server:8080` | Movies |
| **Tautulli** | `http://tautulli.plex-server:8080` | Plex Statistics |
| **Portainer** | `http://portainer.plex-server:8080` | Docker Management |

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

Containers are configured with **optimized CPU and RAM limits** to prevent system crashes on the Orange Pi 5 Pro (8GB RAM, 8 cores):

### Current Resource Allocation:
*   **Plex:** 3GB RAM / 3 CPUs (reduced to prevent crashes during transcoding)
*   **qBittorrent:** 800MB RAM / 1.5 CPUs
*   **Bazarr:** 500MB RAM / 1 CPU
*   **Sonarr/Radarr:** 400MB RAM / 1 CPU each
*   **Overseerr/Prowlarr/Tautulli:** 500MB RAM / 1 CPU each
*   **Others:** Optimized for minimal footprint

**Total:** ~9.3GB RAM / 15 CPUs (within safe limits for your hardware)

### ⚠️ Important Stability Notes:

1.  **Swap Configuration (Recommended):**
    If your system crashes with "Out of Memory" errors, enable swap:
    ```bash
    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    ```

2.  **Monitor Resources:**
    Check system health with:
    ```bash
    ./scripts/monitor.sh
    ```

3.  **Reduce Transcoding Load:**
    In Plex settings:
    *   Disable "Use hardware acceleration" if crashes persist
    *   Set "Transcoder temporary directory" to `/tmp` (uses RAM, faster)
    *   Limit "Maximum simultaneous video transcode" to 1-2

## 🔒 Remote Access

*   **Tailscale:** Included for secure remote access without opening ports.
*   **Direct Play:** Configure Plex clients to "Maximum Quality" to avoid transcoding over the VPN.

## 🔄 Maintenance

*   **Backups:** Run `./scripts/backup.sh` to backup your configurations.
