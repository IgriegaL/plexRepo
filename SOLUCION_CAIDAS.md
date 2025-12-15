# 🔧 Solución a Caídas del Sistema - Orange Pi 5 Pro

## 🔴 Problema Identificado

Tu Orange Pi 5 Pro se caía periódicamente debido a **sobreasignación de recursos**:

### Antes (causaba crashes):
- **Total CPUs:** 25.5 de 8 disponibles (312% de sobreasignación)
- **Total RAM:** ~13.9GB de ~7.5GB utilizables
- **Plex:** 4GB RAM + 6 CPUs (excesivo para RK3588)
- **Immich ML:** 1.5GB RAM + 2 CPUs (procesamiento intensivo)
- **Sin swap configurado:** OOM killer mataba procesos abruptamente

### Después (optimizado):
- **Total CPUs:** ~15 (distribuidos eficientemente)
- **Total RAM:** ~9.3GB (con margen para el sistema)
- **Plex:** 3GB RAM + 3 CPUs
- **Immich ML:** 1GB RAM + 1 CPU
- **Scripts de monitoreo y swap incluidos**

---

## ✅ Cambios Aplicados

### 1. Reducción de Límites en `docker-compose.yml`

| Servicio | CPU (antes → después) | RAM (antes → después) |
|----------|----------------------|----------------------|
| **Plex** | 6 → 3 CPUs | 4GB → 3GB |
| **Immich Server** | 2 → 1.5 CPUs | 2GB → 1.5GB |
| **Immich ML** | 2 → 1 CPU | 1.5GB → 1GB |
| **qBittorrent** | 2 → 1.5 CPUs | 1GB → 800MB |
| **Bazarr** | 1.5 → 1 CPU | 600MB → 500MB |
| **Sonarr** | 1.5 → 1 CPU | 500MB → 400MB |
| **Radarr** | 1.5 → 1 CPU | 500MB → 400MB |
| **Overseerr** | 1.5 → 1 CPU | 600MB → 500MB |
| **Prowlarr** | 1.5 → 1 CPU | 600MB → 500MB |

### 2. Nuevos Scripts de Gestión

#### `scripts/monitor.sh`
- Monitorea uso de RAM, CPU, temperatura y estado de contenedores
- Detecta problemas antes de que causen crashes
- **Uso:**
  ```bash
  chmod +x scripts/monitor.sh
  ./scripts/monitor.sh
  
  # Para monitoreo continuo:
  watch -n 5 ./scripts/monitor.sh
  ```

#### `scripts/setup-swap.sh`
- Configura 4GB de swap para prevenir OOM kills
- **Uso:**
  ```bash
  chmod +x scripts/setup-swap.sh
  sudo ./scripts/setup-swap.sh
  ```

### 3. Documentación Actualizada

- `README.md` ahora incluye sección de estabilidad
- Guías para configurar swap y reducir transcoding
- Instrucciones para desactivar Immich ML si causa problemas

---

## 🚀 Pasos a Seguir AHORA

### Paso 1: Aplicar los Cambios
```bash
cd /Users/ms/plexRepo

# Pull los cambios del repositorio
git pull

# Detener contenedores actuales
docker compose down

# Reiniciar con nuevos límites
docker compose up -d
```

### Paso 2: Configurar Swap (IMPORTANTE)
```bash
# Hacer los scripts ejecutables
chmod +x scripts/monitor.sh scripts/setup-swap.sh

# Configurar swap de 4GB
sudo scripts/setup-swap.sh

# Verificar que funciona
free -h
```

### Paso 3: Monitorear el Sistema
```bash
# Primera ejecución para ver el estado actual
./scripts/monitor.sh

# Para monitoreo en tiempo real (cada 5 segundos)
watch -n 5 ./scripts/monitor.sh
```

### Paso 4: Ajustes Adicionales en Plex (Opcional pero Recomendado)

Si sigues teniendo crashes al transcodear:

1. Abre Plex Web UI: `http://192.168.1.50:32400/web`
2. Ve a **Settings** → **Transcoder**
3. Ajusta:
   - ✅ **Transcoder temporary directory:** `/tmp` (más rápido)
   - ✅ **Maximum simultaneous video transcode:** `1` (previene sobrecarga)
   - ⚠️ **Use hardware acceleration:** Probar desactivar si hay crashes
   - ✅ **Transcoder quality:** `Automatic` o `Prefer higher speed encoding`

---

## 🔍 Monitoreo Post-Cambios

### Comandos Útiles:

```bash
# Ver uso de memoria por contenedor
docker stats

# Ver logs de un contenedor específico
docker logs plex
docker logs immich_machine_learning

# Ver temperatura de CPU
cat /sys/class/thermal/thermal_zone0/temp

# Ver procesos que más consumen
htop  # o 'top' si no tienes htop

# Ver logs del sistema (crashes anteriores)
sudo journalctl -xe | grep -i "oom\|kill"
```

### Señales de Alerta:

⚠️ **Memoria >85%** → Reducir más límites o desactivar servicios no esenciales  
⚠️ **Temperatura >75°C** → Mejorar ventilación o reducir carga  
⚠️ **Contenedores reiniciándose** → Revisar logs con `docker logs <nombre>`  
⚠️ **Swap >50% usado** → Aumentar RAM o reducir contenedores activos

---

## 🛠️ Troubleshooting

### Si el sistema sigue cayéndose:

1. **Desactivar Immich ML temporalmente:**
   ```bash
   docker stop immich_machine_learning
   ```
   Luego en Immich Web UI → **Administration** → **Settings** → **Machine Learning** → Desactivar

2. **Desactivar hardware transcoding en Plex:**
   Settings → Transcoder → Desmarcar "Use hardware acceleration"

3. **Reducir más límites de Plex:**
   En `docker-compose.yml` cambiar a:
   ```yaml
   mem_limit: 2g
   cpus: 2
   ```

4. **Verificar logs del kernel:**
   ```bash
   sudo dmesg | grep -i "oom\|kill"
   sudo journalctl -b -p err
   ```

---

## 📊 Resultado Esperado

Con estos cambios deberías tener:

✅ Sistema estable sin crashes aleatorios  
✅ Margen de RAM para picos de uso  
✅ Temperatura controlada (<70°C en carga normal)  
✅ Swap como red de seguridad ante picos  
✅ Monitoreo proactivo para detectar problemas

---

## 📝 Notas Finales

- Los límites actuales son **conservadores** para garantizar estabilidad
- Si ves que tienes margen (con `./scripts/monitor.sh`), puedes aumentar gradualmente
- El **swap** es crítico: sin él, el OOM killer matará procesos sin avisar
- **Plex transcoding** es la operación más pesada: úsalo con Direct Play cuando sea posible

---

**Última actualización:** 15 de diciembre de 2025  
**Basado en:** Orange Pi 5 Pro - 8GB RAM - RK3588 (8 cores)
