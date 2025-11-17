# 🧹 Cambios realizados - Limpieza del repositorio

He dejado el repositorio en una versión mínima, manteniendo solo los servicios que actualmente tienes corriendo en tu Orange Pi:

Servicios conservados:
- Plex (lscr.io/linuxserver/plex)
- qBittorrent (lscr.io/linuxserver/qbittorrent)
- Sonarr (lscr.io/linuxserver/sonarr)
- Radarr (lscr.io/linuxserver/radarr)
- Bazarr (lscr.io/linuxserver/bazarr)
- Overseerr (lscr.io/linuxserver/overseerr)
- Prowlarr (lscr.io/linuxserver/prowlarr)
- Prometheus (prom/prometheus)
- Grafana (grafana/grafana)
- cAdvisor (gcr.io/cadvisor/cadvisor)
- Node Exporter (prom/node-exporter)

Archivos y servicios eliminados:
- Traefik (reverse proxy)
- Authelia (SSO)
- Fail2ban
- ClamAV
- Trivy
- Promtail/Loki
- Tautulli
- Watchtower
- Apprise y notificaciones
- Recyclarr, Kometa, Homepage y otras utilidades
- docker-compose.advanced.yml, docker-compose.extras*.yml, docker-compose.security*.yml
- Scripts de seguridad y configuraciones relacionadas (moved/removed)

Cómo recuperar cualquiera de los archivos eliminados:
```bash
# Si fue un borrado accidental, puedes recuperarlo con Git
git log --name-status -- path/to/file
git checkout <commit-sha> -- path/to/dir-or-file
```

Comandos para aplicar esta configuración en el Orange Pi:
```bash
# 1) En el servidor
cd /ruta/a/plexRepo
git pull origin main
cp .env.example .env
nano .env  # Ajustar variables

# 2) Crear directorios de volúmenes si es necesario
sudo mkdir -p /mnt/nvme/docker-volumes/{plex,sonarr,radarr,bazarr,prowlarr,overseerr,qbittorrent}
sudo mkdir -p /mnt/DiscoDuro/{tvserie,movies,downloads}
sudo chown -R $(id -u):$(id -g) /mnt/nvme/docker-volumes
sudo chown -R $(id -u):$(id -g) /mnt/DiscoDuro

# 3) Iniciar servicio base
docker compose up -d

# 4) Limpiar huérfanos (si existe stack previo con servicios extras)
docker compose down --remove-orphans

# 5) Verificar contenedores
docker ps
```

Si quieres que además elimine recursos remanentes (contenedores, volúmenes e imágenes de servicios no usados), puedo prepararte una lista segura de `docker rm`, `docker rmi` y volúmenes que limpiar.
