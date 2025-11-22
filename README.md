# Plex Minimal Stack (Orange Pi)

🚀 **Stack completo de servidor de medios con configuración automática**

## 📦 Servicios incluidos

### Media Center
- **Plex** - Servidor de medios
- **Sonarr** - Gestor de series de TV
- **Radarr** - Gestor de películas
- **Bazarr** - Gestor de subtítulos
- **Overseerr** - Sistema de solicitudes de medios
- **Prowlarr** - Gestor de indexers
- **qBittorrent** - Cliente de descargas

### Monitoreo
- **Prometheus** - Base de datos de métricas
- **Grafana** - Dashboards de visualización
- **cAdvisor** - Métricas de contenedores
- **Node Exporter** - Métricas del sistema

---

## 🚀 Inicio Rápido

### 1. Configuración inicial
```bash
# Clonar repositorio
git clone <tu-repo>
cd plexRepo

# Copiar y editar variables de entorno
cp .env.example .env
nano .env
```

### 2. Crear directorios
```bash
# Crear volúmenes de configuración (SSD/NVMe recomendado)
sudo mkdir -p /mnt/nvme/docker-volumes/{plex,sonarr,radarr,bazarr,prowlarr,overseerr,qbittorrent}

# Crear directorios de medios (HDD de alta capacidad)
sudo mkdir -p /mnt/DiscoDuro/{tvserie,movies,downloads}

# Asignar permisos
sudo chown -R $(id -u):$(id -g) /mnt/nvme/docker-volumes /mnt/DiscoDuro
```

### 3. Levantar servicios
```bash
docker-compose up -d
```

### 4. Verificar servicios
```bash
docker ps
docker-compose logs -f bootstrap
```

---

## 🤖 Configuración Automática (Bootstrap)

Este proyecto incluye un script de **bootstrap automático** que configura las conexiones entre servicios.

### ¿Qué se configura automáticamente?

✅ **Sonarr** → qBittorrent (cliente de descargas)  
✅ **Radarr** → qBittorrent (cliente de descargas)  
✅ **Prowlarr** → Sonarr (sincronización de indexers)  
✅ **Prowlarr** → Radarr (sincronización de indexers)

### Variables necesarias en `.env`

```bash
# API Keys (obtener desde cada servicio: Settings → General → API Key)
SONARR_API_KEY=tu_api_key_aqui
RADARR_API_KEY=tu_api_key_aqui
PROWLARR_API_KEY=tu_api_key_aqui
OVERSEERR_API_KEY=tu_api_key_aqui
BAZARR_API_KEY=tu_api_key_aqui

# qBittorrent (configurar antes de obtener API keys)
QBITTORRENT_WEBUI_PORT=8089
QBITTORRENT_USER=admin
QBITTORRENT_PASS=adminadmin

# Habilitar bootstrap (por defecto: true)
BOOTSTRAP_ENABLE=true
```

### 📖 Guía Completa

Para configuración detallada paso a paso, consulta:

**[📘 SETUP.md - Guía Completa de Configuración](./SETUP.md)**

La guía incluye:
- Obtención de API Keys paso a paso
- Configuración manual de servicios
- Solución de problemas
- Verificación del sistema
- Workflow completo

### Desactivar bootstrap

Si prefieres configurar todo manualmente:
```bash
# En tu archivo .env
BOOTSTRAP_ENABLE=false
```

---

## 🌐 Puertos de Acceso

| Servicio | Puerto | URL |
|----------|--------|-----|
| **Plex** | 32400 | http://localhost:32400/web |
| **Sonarr** | 8989 | http://localhost:8989 |
| **Radarr** | 7878 | http://localhost:7878 |
| **Prowlarr** | 9696 | http://localhost:9696 |
| **Bazarr** | 6767 | http://localhost:6767 |
| **Overseerr** | 5055 | http://localhost:5055 |
| **qBittorrent** | 8089 | http://localhost:8089 |
| **Grafana** | 3000 | http://localhost:3000 |
| **Prometheus** | 9090 | http://localhost:9090 |
| **cAdvisor** | 8081 | http://localhost:8081 |

---

## 🔧 Scripts Útiles

```bash
# Verificar salud de servicios
./scripts/test-health.sh

# Verificar configuración
./scripts/test-config.sh

# Verificar conectividad entre servicios
./scripts/test-connectivity.sh

# Backup de configuraciones
./scripts/backup.sh

# Actualizar y reiniciar servicios
./scripts/update_and_restart.sh

# Limpiar recursos de Docker
./scripts/prune_docker_resources.sh
```

---

## 📊 Monitoreo

El sistema incluye monitoreo completo con Grafana:

1. Accede a **Grafana**: http://localhost:3000
2. Login con credenciales de `.env` (default: admin/admin)
3. Los dashboards ya están configurados automáticamente
4. Visualiza métricas de:
   - Uso de CPU y memoria
   - Estado de contenedores
   - Tráfico de red
   - Uso de disco

---

## 🔄 Workflow de Uso

1. 👤 Usuario solicita contenido en **Overseerr**
2. 📡 **Overseerr** envía solicitud a **Sonarr/Radarr**
3. 🔍 **Sonarr/Radarr** busca en indexers de **Prowlarr**
4. ⬇️ Descarga con **qBittorrent**
5. 📁 Archivo movido a `/tv` o `/movies`
6. 📝 **Bazarr** descarga subtítulos
7. 🎬 **Plex** detecta y agrega a biblioteca
8. 📊 **Grafana** monitorea todo el sistema

---

## 🛠️ Mantenimiento

### Ver logs
```bash
# Todos los servicios
docker-compose logs -f

# Servicio específico
docker-compose logs -f plex
docker-compose logs -f sonarr
```

### Reiniciar servicio
```bash
docker-compose restart plex
```

### Actualizar servicios
```bash
docker-compose pull
docker-compose up -d
```

### Detener todo
```bash
docker-compose down
```

### Eliminar volúmenes (⚠️ CUIDADO - elimina datos)
```bash
docker-compose down -v
```

---

## 📚 Documentación Adicional

- **[SETUP.md](./SETUP.md)** - Guía completa de configuración inicial
- **[SECURITY.md](./SECURITY.md)** - Consideraciones de seguridad
- **[CLEANUP.md](./CLEANUP.md)** - Historial de limpieza del proyecto

---

## 🆘 Solución de Problemas

### Bootstrap no funciona
```bash
# Ver logs del bootstrap
docker logs bootstrap

# Re-ejecutar manualmente
docker-compose up bootstrap
```

### Servicios no se conectan
```bash
# Verificar redes
docker network ls
docker network inspect plexrepo_media

# Verificar conectividad
docker exec sonarr ping -c 2 qbittorrent
```

### API Keys inválidas
1. Verifica en la UI de cada servicio: Settings → General → API Key
2. Actualiza `.env` con las keys correctas
3. Reinicia: `docker-compose restart bootstrap`

### Permisos de archivos
```bash
# Verificar PUID/PGID
id -u
id -g

# Corregir permisos
sudo chown -R $(id -u):$(id -g) /mnt/nvme/docker-volumes
sudo chown -R $(id -u):$(id -g) /mnt/DiscoDuro
```

**Para más detalles, consulta [SETUP.md - Solución de Problemas](./SETUP.md#solución-de-problemas)**

---

## ⚠️ Notas Importantes

- **Plex Claim Token** expira en 4 minutos - úsalo inmediatamente
- **Cambia contraseñas por defecto** especialmente en qBittorrent y Grafana
- **API Keys** deben obtenerse después de la primera ejecución de cada servicio
- El script bootstrap es **idempotente** - puedes ejecutarlo múltiples veces

---

## 🔐 Seguridad

- No expongas puertos directamente a internet sin protección
- Usa contraseñas seguras
- Considera usar VPN para descargas
- Mantén los servicios actualizados
- Revisa [SECURITY.md](./SECURITY.md) para más detalles

---

## 📝 Licencia

Este proyecto está disponible bajo la licencia MIT.

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:
1. Fork el proyecto
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request

---

**¿Necesitas ayuda?** Consulta [SETUP.md](./SETUP.md) para una guía paso a paso detallada.

Si necesitas volver a añadir servicios opcionales (Traefik, Authelia, Apprise, etc.), restaura
los archivos desde el historial de Git o usa una rama separada donde estén activos.
