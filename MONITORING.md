# Monitoreo con Netdata en Docker

## ¿Qué es Netdata?

Netdata es un sistema de monitoreo en tiempo real que proporciona:
- 📊 Gráficas de CPU, RAM, Swap, Disco, Red
- 🐳 Métricas de todos tus contenedores Docker
- 🌡️ Temperatura del sistema
- ⚠️ Alertas automáticas
- 📱 Acceso web desde cualquier dispositivo
- 💾 Muy ligero: solo ~150MB RAM y 0.5 CPU

## Configuración

Ya está agregado a `docker-compose.yml` con límites apropiados para Orange Pi 5.

### Iniciar Netdata

```bash
# Iniciar solo Netdata
docker compose up -d netdata

# O reiniciar todo
docker compose down && docker compose up -d
```

### Acceder a Netdata

Abre en tu navegador:
- Local: `http://localhost:19999`
- Remoto (via Tailscale): `http://[IP-ORANGEPI]:19999`

## Características principales

### Métricas disponibles

1. **Sistema**
   - CPU por core (8 cores individuales)
   - RAM y Swap en tiempo real
   - Temperatura del SoC
   - Carga del sistema
   - Procesos activos

2. **Docker**
   - CPU y RAM por contenedor
   - Red por contenedor
   - Contenedores corriendo/detenidos
   - Logs de errores

3. **Disco**
   - Uso de espacio
   - I/O read/write
   - Latencia

4. **Red**
   - Tráfico entrante/saliente
   - Conexiones activas

### Alertas automáticas

Netdata viene con alertas preconfiguradas:
- ⚠️ RAM >80%
- ⚠️ Swap >50%
- ⚠️ CPU >90%
- ⚠️ Disco >90%
- ⚠️ Temperatura alta
- ⚠️ OOM kills detectados

## Ventajas vs scripts bash

| Característica | Scripts bash | Netdata |
|----------------|--------------|---------|
| Gráficas históricas | ❌ Solo texto | ✅ Gráficas interactivas |
| Tiempo real | ❌ Cada 15 min | ✅ Actualización cada segundo |
| Alertas | ❌ Manual | ✅ Automáticas |
| Interfaz | ❌ Terminal | ✅ Web UI moderna |
| Histórico | ✅ 7 días en logs | ✅ Configurable (1 hora default) |
| Recursos | ✅ ~0MB | ⚠️ ~150MB |
| Acceso remoto | ❌ Solo SSH | ✅ Web desde cualquier lugar |
| Métricas Docker | ❌ Básico | ✅ Detallado |

## Recomendación

**Usa ambos:**
1. **Netdata** → Para monitoreo en tiempo real y diagnóstico activo
2. **Scripts bash** → Como respaldo para logs históricos y análisis post-mortem

Los scripts solo usan recursos cuando se ejecutan, Netdata corre 24/7 pero te da visibilidad instantánea.

## Configuración avanzada (opcional)

### Netdata Cloud (gratis)

Para acceder remotamente sin Tailscale:

1. Crea cuenta en https://app.netdata.cloud
2. Obtén el token de claim
3. Agrega a `.env`:
```bash
NETDATA_CLAIM_TOKEN=tu-token-aqui
```
4. Reinicia: `docker compose up -d netdata`

### Aumentar retención de datos

Por defecto Netdata guarda 1 hora. Para guardar más:

```bash
# Crear archivo de configuración
docker exec -it netdata cat /etc/netdata/netdata.conf > netdata.conf

# Editar y cambiar:
[db]
    mode = dbengine
    retention = 86400  # 24 horas en segundos
    
# Mover a volumen
docker cp netdata.conf netdata:/etc/netdata/netdata.conf
docker compose restart netdata
```

### Alertas por webhook/Telegram

Netdata puede enviar alertas a:
- Discord
- Slack
- Telegram
- Email
- Webhook personalizado

Ver: https://learn.netdata.cloud/docs/alerting/notifications

## Comparación con otras soluciones

### Grafana + Prometheus + cAdvisor
- ✅ Más potente y profesional
- ❌ Consume ~500MB RAM
- ❌ Configuración compleja
- ❌ No recomendado para Orange Pi 4GB

### Portainer Stats
- ✅ Ya lo tienes instalado
- ⚠️ Solo métricas básicas de Docker
- ❌ No muestra sistema completo (CPU, temp, OOM)
- ✅ Útil para gestión de contenedores

### Dozzle
- ✅ Ya lo tienes instalado
- ✅ Perfecto para ver logs
- ❌ No tiene métricas de rendimiento
- ✅ Complementa bien con Netdata

## Troubleshooting

### Netdata no inicia
```bash
# Ver logs
docker logs netdata

# Verificar permisos
ls -la /var/run/docker.sock
```

### No se ven métricas de Docker
```bash
# Verificar socket
docker exec netdata ls -la /var/run/docker.sock

# Reiniciar contenedor
docker compose restart netdata
```

### Consume mucha RAM
```bash
# Reducir límite en docker-compose.yml
mem_limit: 100m  # En vez de 150m

# Aplicar cambio
docker compose up -d netdata
```

## Comandos útiles

```bash
# Ver estado
docker ps | grep netdata

# Ver logs
docker logs -f netdata

# Reiniciar
docker compose restart netdata

# Detener (si consume muchos recursos)
docker stop netdata

# Ver uso de recursos de Netdata
docker stats netdata --no-stream
```

## Conclusión

Netdata es ideal para tu Orange Pi porque:
1. Consume pocos recursos (150MB vs 500MB+ de Grafana)
2. Configuración automática, sin setup complejo
3. Interfaz web accesible desde cualquier dispositivo
4. Alertas automáticas sin configurar nada
5. Complementa tus scripts bash (tiempo real + histórico)

Para máxima estabilidad, puedes mantener Netdata detenido normalmente y solo iniciarlo cuando necesites diagnosticar: `docker start netdata`
