# Media Server Setup

This project sets up a media server using Docker Compose. It includes services like Plex, Emby, qBittorrent, Sonarr, Radarr, Jackett, Overseerr, and Prowlarr.

## Requirements

- Docker
- Docker Compose

## Configuration

1. Clone this repository to your local machine.
2. Create a `.env` file in the root directory of the project with the following content:

    ```env
    PUID=1001
    PGID=1001
    TZ=Chile/Continental

    # Replace with directory on your system : mnt/DiscoDuro

    PLEX_CONFIG_VOLUME=/mnt/DiscoDuro/docker/plex
    TV_SERIES_VOLUME=/mnt/DiscoDuro/tvserie
    MOVIES_VOLUME=/mnt/DiscoDuro/movies
    QBITTORRENT_CONFIG_VOLUME=/mnt/DiscoDuro/qbittorrent/appdata
    DOWNLOADS_VOLUME=/mnt/DiscoDuro/downloads
    SONARR_CONFIG_VOLUME=/mnt/DiscoDuro/sonarr
    RADARR_CONFIG_VOLUME=/mnt/DiscoDuro/pvr/radarr
    JACKETT_CONFIG_VOLUME=/mnt/DiscoDuro/jackett
    OVERSEERR_CONFIG_VOLUME=/mnt/DiscoDuro/opt/pvr/overseerr
    PROWLARR_CONFIG_VOLUME=/mnt/DiscoDuro/prowlarr
    ```

3. Modify the paths in the [.env](http://_vscodecontentref_/0) file to match the directories on your system.

## Usage

To start the services, run the following command in the root directory of the project:

```sh
docker-compose up -d
```

This will download the necessary Docker images and start the containers in the background.

Included Services
Plex: Media server to organize and stream your movies and TV shows.
Emby: Alternative to Plex for organizing and streaming your media.
qBittorrent: BitTorrent client for downloading files.
Sonarr: TV series manager.
Radarr: Movie manager.
Jackett: Proxy for torrent indexers.
Overseerr: Tool for managing content requests.
Prowlarr: Indexer manager for Sonarr and Radarr.
Ports
Plex: Depends on network configuration.
Emby: HTTP 8096, HTTPS 8920
qBittorrent: WebUI 8089, Torrenting 6881
Sonarr: 8989
Radarr: 7878
Jackett: 9117
Overseerr: 5055
Prowlarr: 9696
Automatic Restart
The containers are configured to restart automatically unless stopped manually (restart: unless-stopped).

Resources
Docker
Docker Compose
LinuxServer.io
Contributions
Contributions are welcome. Please open an issue or a pull request to discuss any changes.