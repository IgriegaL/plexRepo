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