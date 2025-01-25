# Media Server Setup

This project sets up a media server using Docker Compose. It includes services like Plex, Emby, qBittorrent, Sonarr, Radarr, Jackett, Overseerr, Prowlarr, and Bazarr.

## Requirements

- Docker
- Docker Compose

## Configuration

1. Clone this repository to your local machine.
2. Create a `.env` file in the root directory of the project with the following content:

    * Add these permissions to your user ID:
      ```sh
      sudo chmod -R 777 /root/plex /mnt/DiscoDuro/tvserie /mnt/DiscoDuro/movies /mnt/DiscoDuro/qbittorrent/appdata /mnt/DiscoDuro/downloads /mnt/DiscoDuro/sonarr /mnt/DiscoDuro/pvr/radarr /mnt/DiscoDuro/jackett /mnt/DiscoDuro/opt/pvr/overseerr /mnt/DiscoDuro/prowlarr /mnt/DiscoDuro/bazarr
      ```

    ```env
    PUID={yourId or root}
    PGID={yourId or root}
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
    BAZARR_CONFIG_VOLUME=/mnt/DiscoDuro/bazarr
    ```

3. Modify the paths in the [.env](http://_vscodecontentref_/1) file to match the directories on your system.

## Usage

To start the services, run the following command in the root directory of the project:

```sh
docker-compose up -d