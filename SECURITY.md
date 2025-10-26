# 🔐 Guía de Seguridad

Sistema de seguridad completo para tu servidor multimedia.

## 🎯 Servicios de Seguridad Implementados

### Autenticación y Acceso
- **Authelia** - SSO con autenticación de dos factores (2FA)
- **Fail2ban** - Protección contra ataques de fuerza bruta

### Protección de Datos
- **Docker Secrets** - Gestión segura de credenciales
- **Backups Encriptados** - Copias de seguridad con AES-256

### Detección de Amenazas
- **ClamAV** - Antivirus para descargas
- **Trivy** - Escaneo de vulnerabilidades en imágenes
- **CrowdSec** - Detección de intrusiones

### Monitoreo y Logs
- **Loki + Promtail** - Logs centralizados
- **ModSecurity** - Web Application Firewall (WAF)

### Redes
- **Segmentación avanzada** - 4 redes aisladas
- **Rate Limiting** - Protección contra DDoS

---

## 🚀 Configuración Rápida (30 minutos)

### Paso 1: Generar Secrets

```bash
# Generar secrets de Authelia
./scripts/security/generate-secrets.sh
```

### Paso 2: Configurar Usuario Admin

```bash
# Generar hash de password
docker run authelia/authelia:latest authelia crypto hash generate argon2 --password 'tu_password_seguro'

# Copiar el hash y editar
nano authelia/users_database.yml
# Reemplazar "CHANGEME" con el hash generado
```

### Paso 3: Configurar Email de Alertas

```bash
nano .env
# Agregar:
SECURITY_ALERT_EMAIL=tu-email@ejemplo.com
```

### Paso 4: Iniciar Servicios de Seguridad

```bash
# Iniciar todos los servicios de seguridad
docker-compose -f docker-compose.yml -f docker-compose.security.yml up -d

# O solo algunos
docker-compose -f docker-compose.security.yml up -d authelia fail2ban clamav
```

### Paso 5: Configurar 2FA

1. Accede a: `http://localhost:9091` o `https://auth.tudominio.com`
2. Login con usuario `admin` y tu password
3. Escanea el código QR con Google Authenticator / Authy
4. Ingresa el código de 6 dígitos
5. ✅ 2FA activado!

---

## 🔒 Authelia - Autenticación con 2FA

### Configuración de Servicios Protegidos

Todos estos servicios requieren 2FA:
- Sonarr, Radarr, Prowlarr, Bazarr
- Grafana, Prometheus
- Traefik, Tautulli, qBittorrent

**Plex y Overseerr** están en bypass (usan su propia autenticación).

### Agregar Usuarios

```bash
# 1. Generar password hash
docker run authelia/authelia:latest authelia crypto hash generate argon2 --password 'password_usuario'

# 2. Editar users_database.yml
nano authelia/users_database.yml

# 3. Agregar usuario
users:
  nuevo_usuario:
    displayname: "Nombre Usuario"
    password: "$argon2id$v=19$m=65536,t=3,p=4$HASH_AQUI"
    email: usuario@ejemplo.com
    groups:
      - users  # o 'admins' para acceso completo

# 4. Reiniciar Authelia
docker-compose -f docker-compose.security.yml restart authelia
```

### Políticas de Acceso

```yaml
# En authelia/configuration.yml

# Bypass (sin autenticación)
- domain: "plex.${DOMAIN}"
  policy: bypass

# One-factor (solo password)
- domain: "overseerr.${DOMAIN}"
  policy: one_factor

# Two-factor (password + 2FA)
- domain: "sonarr.${DOMAIN}"
  policy: two_factor
  subject:
    - "group:admins"  # Solo admins
```

---

## 🛡️ Fail2ban - Protección Anti Fuerza Bruta

### Configuración

Fail2ban bloquea IPs después de intentos fallidos:

- **SSH**: 5 intentos en 10 min → Ban 1 hora
- **Plex**: 10 intentos en 5 min → Ban 24 horas
- **Sonarr/Radarr**: 5 intentos en 10 min → Ban 1 hora
- **Traefik**: 3 intentos en 5 min → Ban 2 horas

### Ver IPs Bloqueadas

```bash
# Ver todas las IPs baneadas
docker exec fail2ban fail2ban-client status

# Ver IPs baneadas de un servicio específico
docker exec fail2ban fail2ban-client status plex

# Desbanear una IP
docker exec fail2ban fail2ban-client set plex unbanip 192.168.1.100
```

### Personalizar Reglas

```bash
# Editar configuración
nano fail2ban/jail.d/custom.conf

# Ejemplo: Cambiar tiempo de ban
[plex]
bantime = 48h  # Cambiar de 24h a 48h
maxretry = 3   # Cambiar de 10 a 3

# Reiniciar
docker-compose -f docker-compose.security.yml restart fail2ban
```

---

## 🦠 ClamAV - Antivirus

### Escaneo Manual

```bash
# Escanear descargas
./scripts/security/scan-downloads.sh
```

### Escaneo Automático

```bash
# Agregar a crontab para escaneo cada 6 horas
crontab -e

# Agregar:
0 */6 * * * /ruta/completa/scripts/security/scan-downloads.sh
```

### Ver Archivos en Cuarentena

```bash
# Listar archivos en cuarentena
ls -lh clamav/quarantine/

# Restaurar archivo (si es falso positivo)
mv clamav/quarantine/archivo.ext /mnt/DiscoDuro/downloads/
```

---

## 🔍 Trivy - Escaneo de Vulnerabilidades

### Escanear Todas las Imágenes

```bash
./scripts/security/scan-vulnerabilities.sh
```

### Escanear Imagen Específica

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity CRITICAL,HIGH \
  lscr.io/linuxserver/plex:latest
```

### Automatizar Escaneos

```bash
# Escanear semanalmente
crontab -e

# Agregar:
0 2 * * 0 /ruta/completa/scripts/security/scan-vulnerabilities.sh
```

---

## 📊 Loki - Logs Centralizados

### Ver Logs en Grafana

1. Accede a Grafana: `http://localhost:3000`
2. Explore > Loki
3. Consultas útiles:

```logql
# Logs de un contenedor específico
{container_name="plex"}

# Errores en todos los contenedores
{job="docker"} |= "error"

# Logs de autenticación
{job="auth"}

# Intentos de login fallidos
{container_name="authelia"} |= "failed"
```

### Retención de Logs

Por defecto: **31 días**

Cambiar en `loki/loki-config.yml`:
```yaml
limits_config:
  retention_period: 744h  # 31 días (cambiar según necesites)
```

---

## 🔐 Docker Secrets

### Crear Nuevo Secret

```bash
# Crear secret
echo "mi_valor_secreto" | docker secret create mi_secret -

# Usar en docker-compose
services:
  mi_servicio:
    secrets:
      - mi_secret
    environment:
      - MI_VAR_FILE=/run/secrets/mi_secret

secrets:
  mi_secret:
    external: true
```

### Listar Secrets

```bash
docker secret ls
```

### Eliminar Secret

```bash
docker secret rm mi_secret
```

---

## 💾 Backups Encriptados

### Crear Backup

```bash
./scripts/security/backup-encrypted.sh
```

El backup incluye:
- Configuraciones de todos los servicios
- Archivos docker-compose
- Scripts
- **NO incluye:** medios (películas/series) por tamaño

### Restaurar Backup

```bash
# Desencriptar y extraer
gpg --decrypt --passphrase-file ./secrets/backup_password.txt \
  ~/plex-backups-encrypted/plex-backup-TIMESTAMP.tar.gz.gpg | tar -xzf -
```

### Backup Automático

```bash
# Backup diario a las 3 AM
crontab -e

# Agregar:
0 3 * * * /ruta/completa/scripts/security/backup-encrypted.sh
```

---

## 🌐 Segmentación de Redes

### Redes Configuradas

1. **frontend** - Servicios públicos (Plex, Overseerr, Traefik)
2. **backend** - Servicios internos (Sonarr, Radarr) - SIN internet directo
3. **vpn** - (removido) Esta red ya no se crea por defecto
4. **monitoring** - Prometheus, Grafana, Loki - Aislado

### Ventajas

- Limita superficie de ataque
- Servicios internos no accesibles desde internet
  - Torrents no viajan por una VPN integrada en este repositorio (opcional: integrar manualmente)
- Monitoreo aislado

---

## 🚨 Monitoreo de Seguridad

### Dashboard de Seguridad en Grafana

1. Grafana > Dashboards > Import
2. Importar dashboard de seguridad (ID: crear custom)
3. Métricas a monitorear:
   - IPs baneadas por Fail2ban
   - Intentos de login fallidos
   - Archivos infectados detectados
   - Vulnerabilidades por servicio

### Alertas

Configurar en Prometheus:

```yaml
# prometheus-alerts.yml
groups:
  - name: security
    rules:
      - alert: MultipleFailedLogins
        expr: rate(authelia_authentication_failed_total[5m]) > 5
        annotations:
          summary: "Múltiples intentos de login fallidos"
      
      - alert: MalwareDetected
        expr: clamav_infected_files > 0
        annotations:
          summary: "ClamAV detectó archivos infectados"
```

---

## 📋 Checklist de Seguridad

### Configuración Inicial
- [ ] Secrets generados (`./scripts/security/generate-secrets.sh`)
- [ ] Password de admin cambiado en Authelia
- [ ] 2FA configurado para tu usuario
- [ ] Email de alertas configurado
- [ ] Fail2ban activo

### Mantenimiento Semanal
- [ ] Revisar IPs baneadas
- [ ] Escanear vulnerabilidades (`./scripts/security/scan-vulnerabilities.sh`)
- [ ] Revisar logs de autenticación en Loki
- [ ] Verificar backups encriptados

### Mantenimiento Mensual
- [ ] Actualizar imágenes Docker
- [ ] Revisar políticas de acceso de Authelia
- [ ] Limpiar archivos en cuarentena de ClamAV
- [ ] Rotar secrets si es necesario

---

## 🆘 Troubleshooting

### Authelia: No puedo hacer login

```bash
# Ver logs
docker logs authelia

# Verificar configuración
docker exec authelia authelia validate-config /config/configuration.yml

# Resetear password
# Generar nuevo hash y actualizar users_database.yml
```

### Fail2ban: IP propia baneada

```bash
# Desbanear
docker exec fail2ban fail2ban-client set <jail> unbanip <tu_ip>

# Ejemplo:
docker exec fail2ban fail2ban-client set plex unbanip 192.168.1.100

# Agregar a whitelist
nano fail2ban/jail.d/custom.conf
# Agregar:
ignoreip = 127.0.0.1/8 192.168.1.0/24
```

### ClamAV: Falso positivo

```bash
# Restaurar archivo
mv clamav/quarantine/archivo.ext /mnt/DiscoDuro/downloads/

# Reportar falso positivo a ClamAV
# https://www.clamav.net/reports/fp
```

### Loki: No aparecen logs

```bash
# Verificar Promtail
docker logs promtail

# Verificar conectividad
docker exec promtail wget -O- http://loki:3100/ready

# Reiniciar servicios
docker-compose -f docker-compose.security.yml restart loki promtail

> Nota: En algunas instalaciones se ha eliminado Loki/Promtail del `docker-compose.security.yml` porque no se
> usaba el sistema de logs centralizado y provocaba conflictos de montaje/puertos (por ejemplo `loki/loki-config.yml`
> siendo accidentalmente un directorio o puertos ocupados). Si necesitas reactivar Loki/Promtail, restaura sus
> bloques en `docker-compose.security.yml` y `docker-compose.security-arm64.yml` y asegúrate de que los archivos
> `./loki/loki-config.yml` y `./promtail/promtail-config.yml` existan como archivos YAML regulares.
```

---

## 📚 Recursos

- **Authelia Docs**: https://www.authelia.com/
- **Fail2ban Wiki**: https://github.com/fail2ban/fail2ban/wiki
- **ClamAV Docs**: https://docs.clamav.net/
- **Trivy Docs**: https://aquasecurity.github.io/trivy/
- **Loki Docs**: https://grafana.com/docs/loki/

---

## ⚠️ Importante

1. **Guarda el archivo `secrets/backup_password.txt`** en un lugar seguro
2. **No subas secrets a Git** (ya están en .gitignore)
3. **Cambia passwords por defecto** inmediatamente
4. **Habilita 2FA** en todos los usuarios
5. **Revisa logs regularmente** en Loki/Grafana

---

**Versión:** 3.0.0 - Security Hardened  
**Última actualización:** 26 de Octubre, 2025
