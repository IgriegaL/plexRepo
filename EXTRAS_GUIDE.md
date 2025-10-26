# 🚀 Guía de Servicios Extras

Servicios adicionales que mejoran significativamente la experiencia.

## 📋 Servicios Incluidos

### Fase 1 - Críticos ⭐⭐⭐⭐⭐
- **Recyclarr** - Auto-configuración de calidad
- **Uptime Kuma** - Monitoreo visual simple

### Fase 2 - Muy Útiles ⭐⭐⭐⭐
- **Requestrr** - Bot de Discord/Telegram
- **Autoscan** - Escaneo instantáneo de Plex

### Fase 3 - Mejoras Visuales ⭐⭐⭐
- **Kometa** - Colecciones automáticas
- **Homepage** - Dashboard moderno

### Fase 4 - Mantenimiento ⭐⭐
- **Maintainerr** - Limpieza automática
- **Scrutiny** - Monitoreo de discos

---

## 🚀 Inicio Rápido

### 1. Actualizar .env

```bash
nano .env
```

Agregar las nuevas variables (ver `.env.example`):
- API Keys de servicios
- Plex Token
- TMDB API Key
- IP del host

### 2. Crear Directorios

```bash
mkdir -p recyclarr uptime-kuma requestrr autoscan kometa homepage maintainerr scrutiny tdarr
```

### 3. Iniciar Servicios

```bash
# Todos los servicios extras
docker-compose -f docker-compose.yml -f docker-compose.extras.yml up -d

# O solo algunos
docker-compose -f docker-compose.extras.yml up -d recyclarr uptime-kuma
```

---

## 📖 Configuración Detallada

### 1. Recyclarr - Auto-configuración de Calidad

**¿Qué hace?**
- Configura automáticamente perfiles de calidad en Sonarr/Radarr
- Usa configuraciones óptimas de TRaSH Guides
- Actualiza formatos de release

**Configuración:**

1. Obtener API Keys:
   - Sonarr: Settings > General > API Key
   - Radarr: Settings > General > API Key

2. Agregar a `.env`:
```env
SONARR_API_KEY=tu_api_key
RADARR_API_KEY=tu_api_key
```

3. Ejecutar primera vez:
```bash
docker-compose -f docker-compose.extras.yml up -d recyclarr
docker exec recyclarr recyclarr sync
```

4. Verificar en Sonarr/Radarr:
   - Settings > Profiles
   - Deberías ver perfiles optimizados

**Ejecución automática:**
- Se ejecuta diariamente a las 3 AM
- Actualiza configuraciones automáticamente

---

### 2. Uptime Kuma - Monitoreo Visual

**¿Qué hace?**
- Monitorea uptime de todos los servicios
- Dashboard hermoso y simple
- Notificaciones cuando algo cae

**Configuración:**

1. Acceder: `http://localhost:3001`

2. Crear cuenta (primera vez)

3. Agregar monitores:
   - Click en "Add New Monitor"
   - Monitor Type: HTTP(s)
   - Friendly Name: Plex
   - URL: `http://plex:32400/web`
   - Heartbeat Interval: 60 segundos
   - Retries: 3

4. Repetir para cada servicio:
   - Sonarr: `http://sonarr:8989`
   - Radarr: `http://radarr:7878`
   - Overseerr: `http://overseerr:5055`
   - etc.

5. Configurar notificaciones:
   - Settings > Notifications
   - Agregar Discord, Telegram, Email, etc.

**Página de estado pública:**
- Settings > Status Page
- Create Status Page
- Comparte la URL con usuarios

---

### 3. Requestrr - Bot de Discord/Telegram

**¿Qué hace?**
- Solicitar contenido desde Discord/Telegram
- Comandos simples: `/movie Inception`
- Notificaciones cuando está listo

**Configuración Discord:**

1. Crear Bot de Discord:
   - <https://discord.com/developers/applications>
   - New Application
   - Bot > Add Bot
   - Copy Token

2. Invitar bot a tu servidor:
   - OAuth2 > URL Generator
   - Scopes: bot
   - Permissions: Send Messages, Embed Links
   - Copy URL y abre en navegador

3. Configurar Requestrr:
   - Acceder: `http://localhost:4545`
   - Discord > Bot Token: pegar token
   - Discord > Client ID: de la aplicación
   - Save

4. Conectar con Overseerr:
   - Overseerr > URL: `http://overseerr:5055`
   - API Key: de Overseerr
   - Save

5. Probar en Discord:
   - `/movie Inception`
   - El bot responderá con opciones

**Configuración Telegram:**

1. Crear bot con @BotFather
2. Obtener token
3. Requestrr > Telegram > Bot Token
4. Obtener Chat ID con @userinfobot
5. Agregar Chat ID en Requestrr

---

### 4. Autoscan - Escaneo Instantáneo

**¿Qué hace?**
- Notifica a Plex inmediatamente cuando llega contenido
- De horas a segundos

**Configuración:**

1. Crear `autoscan/config.yml`:

```yaml
minimum-age: 10m
scan-delay: 5s
scan-stats: true

plex:
  - url: http://plex:32400
    token: TU_PLEX_TOKEN

triggers:
  sonarr:
    - priority: 5
      rewrite:
        - from: /tv
          to: /tv

  radarr:
    - priority: 5
      rewrite:
        - from: /movies
          to: /movies
```

2. Configurar en Sonarr:
   - Settings > Connect > Webhook
   - URL: `http://autoscan:3030/triggers/sonarr`
   - Method: POST
   - On Download: ✅
   - On Upgrade: ✅

3. Configurar en Radarr:
   - Settings > Connect > Webhook
   - URL: `http://autoscan:3030/triggers/radarr`
   - Method: POST
   - On Download: ✅
   - On Upgrade: ✅

---

### 5. Kometa - Colecciones Automáticas

**¿Qué hace?**
- Crea colecciones automáticas (Marvel, DC, etc.)
- Agrega posters hermosos
- Actualiza metadata

**Configuración:**

1. Obtener Plex Token:
   - <https://support.plex.tv/articles/204059436>

2. Obtener TMDB API Key:
   - <https://www.themoviedb.org/settings/api>

3. Agregar a `.env`:
```env
PLEX_TOKEN=tu_token
TMDB_API_KEY=tu_api_key
```

4. Reiniciar Kometa:
```bash
docker-compose -f docker-compose.extras.yml restart kometa
```

5. Ver logs:
```bash
docker logs kometa -f
```

6. Verificar en Plex:
   - Deberías ver nuevas colecciones
   - Posters actualizados
   - Metadata mejorado

**Se ejecuta automáticamente a las 3 AM diariamente**

---

### 6. Homepage - Dashboard Moderno

**¿Qué hace?**
- Dashboard unificado hermoso
- Widgets de todos los servicios
- Información en tiempo real

**Acceso:** `http://localhost:3002`

**Configuración:**
- Ya viene pre-configurado
- Edita `homepage/services.yaml` para personalizar
- Agrega/quita servicios según necesites

---

### 7. Maintainerr - Limpieza Automática

**¿Qué hace?**
- Elimina contenido no visto después de X días
- Libera espacio automáticamente

**Configuración:**

1. Acceder: `http://localhost:6246`

2. Conectar con Plex y Overseerr

3. Crear reglas:
   - Movies > Not watched in 90 days > Delete
   - TV Shows > Season ended > Not watched > Delete

4. Ejecutar manualmente o programar

---

### 8. Scrutiny - Monitoreo de Discos

**¿Qué hace?**
- Monitorea salud de discos (SMART)
- Predice fallos
- Alertas tempranas

**Acceso:** `http://localhost:8080`

**Configuración:**
- Automática
- Revisa dashboard para ver salud de discos
- Configura alertas en Settings

---

## 📊 Puertos de Servicios Extras

| Servicio | Puerto | URL |
|----------|--------|-----|
| Uptime Kuma | 3001 | <http://localhost:3001> |
| Homepage | 3002 | <http://localhost:3002> |
| Autoscan | 3030 | <http://localhost:3030> |
| Requestrr | 4545 | <http://localhost:4545> |
| Maintainerr | 6246 | <http://localhost:6246> |
| Scrutiny | 8080 | <http://localhost:8080> |

---

## 🎯 Recomendación de Implementación

### Semana 1
1. Recyclarr (30 min)
2. Uptime Kuma (15 min)

### Semana 2
3. Homepage (30 min)
4. Autoscan (30 min)

### Semana 3
5. Requestrr (45 min)
6. Kometa (1 hora)

### Semana 4
7. Maintainerr (1 hora)
8. Scrutiny (30 min)

---

## 🆘 Troubleshooting

### Recyclarr no actualiza configuraciones

```bash
# Ver logs
docker logs recyclarr

# Ejecutar manualmente
docker exec recyclarr recyclarr sync

# Verificar API keys
cat .env | grep API_KEY
```

### Uptime Kuma no monitorea servicios

- Verifica que los servicios estén en la misma red
- Usa nombres de contenedor, no localhost
- Ejemplo: `http://plex:32400` no `http://localhost:32400`

### Requestrr no responde en Discord

- Verifica que el bot esté en el servidor
- Verifica permisos del bot
- Revisa logs: `docker logs requestrr`

---

## 💡 Tips

1. **Empieza con Recyclarr y Uptime Kuma** - Máximo impacto, mínimo esfuerzo

2. **Homepage como página de inicio** - Configura tu navegador para abrir Homepage

3. **Requestrr para familia** - Facilita solicitudes sin enseñar Overseerr

4. **Kometa ejecuta de noche** - No interfiere con uso diario

5. **Scrutiny revisa semanalmente** - Previene fallos de disco

---

**¿Necesitas ayuda?** Revisa los logs de cada servicio con `docker logs nombre_servicio`
