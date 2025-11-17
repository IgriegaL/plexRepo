# Plex Minimal Stack (Orange Pi)

Servicios incluidos:
- Plex
- qBittorrent
- Sonarr
- Radarr
- Bazarr
- Overseerr
- Prowlarr
- Prometheus
- Grafana
- cAdvisor
- Node Exporter

Inicio rápido:
1. Copia y edita el archivo de ejemplo:
```bash
cp .env.example .env
nano .env
```
2. Crea volúmenes y directorios:
```bash
sudo mkdir -p /mnt/nvme/docker-volumes/{plex,sonarr,radarr,bazarr,prowlarr,overseerr,qbittorrent}
sudo mkdir -p /mnt/DiscoDuro/{tvserie,movies,downloads}
sudo chown -R $(id -u):$(id -g) /mnt/nvme/docker-volumes /mnt/DiscoDuro
```
3. Inicia la pila base:
```bash
docker compose up -d
```
4. Comprueba los servicios:
```bash
docker ps
docker compose logs -f
```

Puertos principales:
- Plex: 32400
- Grafana: 3000
- Prometheus: 9090
- Sonarr: 8989
- Radarr: 7878
- Bazarr: 6767
- Overseerr: 5055
- qBittorrent: 8089
- cAdvisor: 8081

Si necesitas volver a añadir servicios opcionales (Traefik, Authelia, Apprise, etc.), restaura
los archivos desde el historial de Git o usa una rama separada donde estén activos.

---

Documentación mínima generada tras limpieza solicitada por el usuario.
