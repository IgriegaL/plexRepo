# 🎓 Guía para Principiantes - Paso a Paso

Esta guía asume que **NO tienes experiencia** con Linux, Docker o servidores. Te llevaré de la mano desde cero hasta tener todo funcionando.

## 📋 Índice

1. [Requisitos Mínimos](#requisitos-mínimos)
2. [Instalación de Sistema Operativo](#paso-1-instalar-sistema-operativo)
3. [Instalación de Docker](#paso-2-instalar-docker)
4. [Descargar el Proyecto](#paso-3-descargar-el-proyecto)
5. [Configuración Básica](#paso-4-configuración-básica)
6. [Crear Carpetas](#paso-5-crear-carpetas)
7. [Iniciar Servicios](#paso-6-iniciar-servicios)
8. [Configurar Cada Servicio](#paso-7-configurar-servicios)
9. [Agregar Contenido](#paso-8-agregar-contenido)
10. [Solución de Problemas](#solución-de-problemas-comunes)

---

## Requisitos Mínimos

### Hardware Necesario

- **Procesador**: Intel i3 o AMD Ryzen 3 (o superior)
- **RAM**: 8GB mínimo (16GB recomendado)
- **Almacenamiento**:
  - 50GB para sistema operativo y programas
  - 500GB+ para películas y series (cuanto más, mejor)
- **Internet**: Conexión estable

### ¿Qué vas a necesitar descargar?

- Ubuntu Server (gratis)
- Este proyecto (gratis)
- Una cuenta de Plex (gratis)

---

## Paso 1: Instalar Sistema Operativo

### Opción A: Si tienes una PC dedicada

1. **Descargar Ubuntu Server**
   - Ve a: <https://ubuntu.com/download/server>
   - Descarga la versión LTS (Long Term Support)
   - Tamaño: ~2GB

2. **Crear USB booteable**
   - Descarga Rufus (Windows): <https://rufus.ie>
   - O Etcher (Mac/Linux): <https://www.balena.io/etcher/>
   - Inserta USB de 8GB mínimo
   - Abre Rufus/Etcher
   - Selecciona la ISO de Ubuntu
   - Selecciona tu USB
   - Click en "Start" o "Flash"
   - Espera 5-10 minutos

3. **Instalar Ubuntu**
   - Inserta el USB en la PC donde instalarás
   - Reinicia y presiona F12 (o F2, DEL según tu PC)
   - Selecciona "Boot from USB"
   - Sigue el instalador:
     - Idioma: Español
     - Teclado: Spanish
     - Red: Configura WiFi/Ethernet
     - Disco: "Use entire disk" (borrará todo)
     - Usuario: Crea tu usuario y contraseña
     - OpenSSH: Marca "Install OpenSSH server"
   - Espera 15-30 minutos
   - Reinicia cuando termine

### Opción B: Si usas tu PC actual (más fácil)

1. **Instalar Docker Desktop**
   - Windows: <https://www.docker.com/products/docker-desktop>
   - Mac: <https://www.docker.com/products/docker-desktop>
   - Instala y reinicia
   - Salta al [Paso 3](#paso-3-descargar-el-proyecto)

---

## Paso 2: Instalar Docker

### En Ubuntu Server

1. **Conectarte a tu servidor**

   Si instalaste Ubuntu en otra PC:

   ```bash
   # Desde tu PC principal, abre terminal y escribe:
   ssh tu_usuario@IP_DEL_SERVIDOR
   # Ejemplo: ssh juan@192.168.1.100
   # Te pedirá la contraseña que creaste
   ```

2. **Actualizar el sistema**

   Copia y pega estos comandos (uno por uno):

   ```bash
   sudo apt update
   ```

   Te pedirá tu contraseña. Escríbela (no se verá) y presiona Enter.

   ```bash
   sudo apt upgrade -y
   ```

   Espera 5-10 minutos.

3. **Instalar Docker**

   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   ```

   Espera 2-3 minutos.

4. **Configurar Docker**

   ```bash
   sudo usermod -aG docker $USER
   ```

   Cierra sesión y vuelve a entrar:

   ```bash
   exit
   # Vuelve a conectarte con ssh
   ```

5. **Instalar Docker Compose**

   ```bash
   sudo apt install docker-compose -y
   ```

6. **Verificar instalación**

   ```bash
   docker --version
   docker-compose --version
   ```

   Deberías ver algo como:

   ```
   Docker version 24.0.x
   docker-compose version 2.x.x
   ```

---

## Paso 3: Descargar el Proyecto

1. **Instalar Git**

   ```bash
   sudo apt install git -y
   ```

2. **Ir a tu carpeta home**

   ```bash
   cd ~
   ```

3. **Descargar el proyecto**

   ```bash
   git clone https://github.com/IgriegaL/plexRepo.git
   ```

4. **Entrar al proyecto**

   ```bash
   cd plexRepo
   ```

5. **Ver los archivos**

   ```bash
   ls
   ```

   Deberías ver:

   ```
   docker-compose.yml
   README.md
   scripts/
   ...
   ```

---

## Paso 4: Configuración Básica

### 4.1 Crear archivo de configuración

```bash
cp .env.example .env
```

### 4.2 Editar configuración

```bash
nano .env
```

**Explicación de cada variable:**

```env
# Tu ID de usuario (déjalo como está)
PUID=1000
PGID=1000

# Tu zona horaria
TZ=Chile/Continental
# Cambia según tu país:
# - España: Europe/Madrid
# - México: America/Mexico_City
# - Argentina: America/Argentina/Buenos_Aires

# TOKEN DE PLEX (MUY IMPORTANTE)
PLEX_CLAIM=claim-xxxxxxxxxxxxxxxx
```

**¿Cómo obtener el token de Plex?**

1. Abre en tu navegador: <https://www.plex.tv/claim/>
2. Inicia sesión con tu cuenta de Plex (crea una si no tienes)
3. Verás un código como: `claim-xxxxxxxxxxxx`
4. **CÓPIALO RÁPIDO** (expira en 4 minutos)
5. Pégalo en el archivo `.env`

```env
# Contraseña de Grafana (cámbiala)
GRAFANA_ADMIN_PASSWORD=MiPasswordSeguro123

# RUTAS DE ALMACENAMIENTO
# Estas son las carpetas donde se guardarán las cosas

# Configuraciones (en disco rápido si tienes SSD)
PLEX_CONFIG_VOLUME=/home/tu_usuario/docker-volumes/plex
SONARR_CONFIG_VOLUME=/home/tu_usuario/docker-volumes/sonarr
RADARR_CONFIG_VOLUME=/home/tu_usuario/docker-volumes/radarr
BAZARR_CONFIG_VOLUME=/home/tu_usuario/docker-volumes/bazarr
PROWLARR_CONFIG_VOLUME=/home/tu_usuario/docker-volumes/prowlarr
OVERSEERR_CONFIG_VOLUME=/home/tu_usuario/docker-volumes/overseerr
QBITTORRENT_CONFIG_VOLUME=/home/tu_usuario/docker-volumes/qbittorrent

# Contenido multimedia (en disco grande)
TV_SERIES_VOLUME=/home/tu_usuario/media/series
MOVIES_VOLUME=/home/tu_usuario/media/peliculas
DOWNLOADS_VOLUME=/home/tu_usuario/media/descargas
```

**Reemplaza `tu_usuario` con tu nombre de usuario real.**

Para saber tu usuario:

```bash
whoami
```

### 4.3 Guardar el archivo

- Presiona `Ctrl + X`
- Presiona `Y` (Yes)
- Presiona `Enter`

---

## Paso 5: Crear Carpetas

```bash
# Crear carpetas de configuración
mkdir -p ~/docker-volumes/plex
mkdir -p ~/docker-volumes/sonarr
mkdir -p ~/docker-volumes/radarr
mkdir -p ~/docker-volumes/bazarr
mkdir -p ~/docker-volumes/prowlarr
mkdir -p ~/docker-volumes/overseerr
mkdir -p ~/docker-volumes/qbittorrent

# Crear carpetas de medios
mkdir -p ~/media/series
mkdir -p ~/media/peliculas
mkdir -p ~/media/descargas
```

Verificar que se crearon:

```bash
ls -la ~/docker-volumes/
ls -la ~/media/
```

---

## Paso 6: Iniciar Servicios

### 6.1 Validar configuración

```bash
./scripts/test-config.sh
```

Si ves errores, revisa el archivo `.env`.

### 6.2 Iniciar servicios

```bash
docker-compose up -d
```

**¿Qué significa esto?**

- `docker-compose`: El programa que maneja los servicios
- `up`: Iniciar
- `-d`: En segundo plano (detached)

Verás algo como:

```
Creating plex ... done
Creating sonarr ... done
Creating radarr ... done
...
```

### 6.3 Esperar a que inicien

Los servicios tardan 2-3 minutos en estar listos.

```bash
# Ver el progreso
docker-compose logs -f
```

Presiona `Ctrl + C` para salir cuando veas que todo está corriendo.

### 6.4 Verificar que funcionan

```bash
docker-compose ps
```

Todos deberían mostrar "Up" y "healthy".

---

## Paso 7: Configurar Servicios

### 7.1 Obtener la IP de tu servidor

```bash
hostname -I
```

Anota la primera IP (ejemplo: `192.168.1.100`)

### 7.2 Acceder desde tu navegador

Desde tu PC principal, abre el navegador y ve a:

#### A) Configurar Plex (PRIMERO)

1. Ve a: `http://IP_SERVIDOR:32400/web`
   - Ejemplo: `http://192.168.1.100:32400/web`

2. Inicia sesión con tu cuenta de Plex

3. **Configurar servidor:**
   - Nombre: "Mi Servidor Plex" (o el que quieras)
   - Permitir acceso fuera de casa: ✅ (si quieres)

4. **Agregar bibliotecas:**

   **Para Series:**
   - Click en "Agregar biblioteca"
   - Tipo: "Programas de TV"
   - Carpeta: Click en "Examinar carpetas"
   - Selecciona: `/tv`
   - Click en "Agregar"

   **Para Películas:**
   - Click en "Agregar biblioteca"
   - Tipo: "Películas"
   - Carpeta: `/movies`
   - Click en "Agregar"

5. ✅ Plex configurado!

#### B) Configurar Prowlarr (Indexadores)

1. Ve a: `http://IP_SERVIDOR:9696`

2. **Primera vez:**
   - Idioma: Español
   - Autenticación: Ninguna (por ahora)

3. **Agregar indexadores:**
   - Click en "Indexers" (menú izquierdo)
   - Click en "Add Indexer"
   - Busca "1337x" o "The Pirate Bay"
   - Click en el nombre
   - Click en "Test" (debe salir ✅)
   - Click en "Save"
   - Repite con 3-4 indexadores más

4. **Conectar con Sonarr:**
   - Click en "Settings" (arriba)
   - Click en "Apps"
   - Click en "+"
   - Selecciona "Sonarr"
   - Configuración:
     - Nombre: Sonarr
     - Sync Level: Full Sync
     - Prowlarr Server: `http://prowlarr:9696`
     - Sonarr Server: `http://sonarr:8989`
     - API Key: (ve a Sonarr para obtenerla)

   **¿Cómo obtener API Key de Sonarr?**
   - Abre `http://IP_SERVIDOR:8989`
   - Settings > General > Security > API Key
   - Cópiala y pégala en Prowlarr

5. **Conectar con Radarr:**
   - Igual que Sonarr pero:
     - Radarr Server: `http://radarr:7878`
     - API Key de Radarr (Settings > General)

6. Click en "Test All" y luego "Save"

7. ✅ Prowlarr configurado!

#### C) Configurar Sonarr (Series)

1. Ve a: `http://IP_SERVIDOR:8989`

2. **Configuración inicial:**
   - Settings > Media Management
   - Root Folders > Add Root Folder
   - Path: `/tv`
   - Click en "OK"

3. **Agregar cliente de descargas:**
   - Settings > Download Clients
   - Click en "+"
   - Selecciona "qBittorrent"
   - Configuración:
     - Name: qBittorrent
     - Host: `qbittorrent`
     - Port: `8089`
     - Username: `admin`
     - Password: `adminadmin`
   - Click en "Test" y luego "Save"

4. ✅ Sonarr configurado!

#### D) Configurar Radarr (Películas)

1. Ve a: `http://IP_SERVIDOR:7878`

2. **Igual que Sonarr:**
   - Root Folder: `/movies`
   - Download Client: qBittorrent (misma config)

3. ✅ Radarr configurado!

#### E) Configurar Overseerr (Solicitudes)

1. Ve a: `http://IP_SERVIDOR:5055`

2. **Configuración inicial:**
   - Idioma: Español
   - Click en "Iniciar configuración"

3. **Conectar con Plex:**
   - Servidor: `plex` (o tu IP:32400)
   - Click en "Iniciar sesión con Plex"
   - Autoriza la aplicación

4. **Conectar con Sonarr:**
   - Servidor: `http://sonarr:8989`
   - API Key: (la de Sonarr)
   - Root Folder: `/tv`
   - Quality Profile: Any
   - Click en "Test" y "Save"

5. **Conectar con Radarr:**
   - Servidor: `http://radarr:7878`
   - API Key: (la de Radarr)
   - Root Folder: `/movies`
   - Quality Profile: Any
   - Click en "Test" y "Save"

6. ✅ Overseerr configurado!

---

## Paso 8: Agregar Contenido

### Opción 1: Desde Overseerr (Recomendado)

1. Ve a: `http://IP_SERVIDOR:5055`
2. Busca una serie o película
3. Click en "Solicitar"
4. Espera 10-30 minutos
5. Aparecerá en Plex automáticamente

### Opción 2: Desde Sonarr/Radarr

**Para Series (Sonarr):**

1. Ve a: `http://IP_SERVIDOR:8989`
2. Click en "Series" > "Add New"
3. Busca la serie
4. Selecciona Root Folder: `/tv`
5. Click en "Add Series"
6. La serie se descargará automáticamente

**Para Películas (Radarr):**

1. Ve a: `http://IP_SERVIDOR:7878`
2. Click en "Movies" > "Add New"
3. Busca la película
4. Selecciona Root Folder: `/movies`
5. Click en "Add Movie"

### ¿Cómo saber si se está descargando?

1. Ve a qBittorrent: `http://IP_SERVIDOR:8089`
   - Usuario: `admin`
   - Contraseña: `adminadmin`
2. Verás las descargas activas

---

## Solución de Problemas Comunes

### ❌ "No puedo acceder a Plex"

**Solución:**

```bash
# Ver si Plex está corriendo
docker ps | grep plex

# Ver logs de Plex
docker logs plex

# Reiniciar Plex
docker-compose restart plex
```

### ❌ "El token de Plex expiró"

**Solución:**

1. Ve a: <https://www.plex.tv/claim/>
2. Obtén un nuevo token
3. Edita `.env`:

   ```bash
   nano .env
   # Cambia PLEX_CLAIM
   ```

4. Reinicia:

   ```bash
   docker-compose restart plex
   ```

### ❌ "No se descargan las series/películas"

**Verificar:**

1. **¿Prowlarr tiene indexadores?**
   - `http://IP:9696` > Indexers
   - Debe haber al menos 3

2. **¿Sonarr/Radarr están conectados a Prowlarr?**
   - Prowlarr > Settings > Apps
   - Debe aparecer Sonarr y Radarr

3. **¿qBittorrent está funcionando?**
   - `http://IP:8089`
   - Login: admin/adminadmin

### ❌ "Error de permisos"

**Solución:**

```bash
# Dar permisos a las carpetas
sudo chown -R $USER:$USER ~/docker-volumes
sudo chown -R $USER:$USER ~/media
```

### ❌ "Docker no inicia"

**Solución:**

```bash
# Reiniciar Docker
sudo systemctl restart docker

# Verificar estado
sudo systemctl status docker
```

### ❌ "No tengo espacio en disco"

**Ver espacio:**

```bash
df -h
```

**Limpiar Docker:**

```bash
docker system prune -a
```

---

## 📊 Resumen de Puertos

| Servicio | Puerto | URL | Usuario | Password |
|----------|--------|-----|---------|----------|
| Plex | 32400 | <http://IP:32400/web> | Tu cuenta Plex | - |
| Overseerr | 5055 | <http://IP:5055> | - | - |
| Sonarr | 8989 | <http://IP:8989> | - | - |
| Radarr | 7878 | <http://IP:7878> | - | - |
| Prowlarr | 9696 | <http://IP:9696> | - | - |
| Bazarr | 6767 | <http://IP:6767> | - | - |
| qBittorrent | 8089 | <http://IP:8089> | admin | adminadmin |
| Grafana | 3000 | <http://IP:3000> | admin | (tu password) |

---

## 🎯 Comandos Útiles para Recordar

```bash
# Ver servicios corriendo
docker-compose ps

# Ver logs de todos los servicios
docker-compose logs -f

# Ver logs de un servicio específico
docker logs plex

# Reiniciar un servicio
docker-compose restart plex

# Reiniciar todos los servicios
docker-compose restart

# Detener todo
docker-compose down

# Iniciar todo
docker-compose up -d

# Actualizar imágenes
docker-compose pull
docker-compose up -d
```

---

## ✅ Checklist Final

- [ ] Ubuntu instalado
- [ ] Docker instalado
- [ ] Proyecto descargado
- [ ] Archivo `.env` configurado
- [ ] Carpetas creadas
- [ ] Servicios iniciados
- [ ] Plex configurado y funcionando
- [ ] Prowlarr con indexadores
- [ ] Sonarr conectado
- [ ] Radarr conectado
- [ ] Overseerr funcionando
- [ ] Primera serie/película descargada

---

## 🎉 ¡Felicidades

Si llegaste hasta aquí, ya tienes tu propio servidor multimedia funcionando.

### Próximos pasos opcionales

1. (Opcional) Integrar VPN manualmente si lo deseas
   - Ver: `docker-compose.advanced.yml`

2. **Configurar acceso desde internet**
   - Ver: Sección de Traefik en README.md

3. **Agregar seguridad con 2FA**
   - Ver: `SECURITY.md`

4. **Configurar notificaciones**
   - Ver: Sección de Apprise en README.md

---

## 🆘 ¿Necesitas Ayuda?

1. **Revisa los logs:**

   ```bash
   docker-compose logs nombre_servicio
   ```

2. **Busca el error en Google:**
   - Copia el mensaje de error
   - Busca: "docker plex [tu error]"

3. **Consulta la documentación:**
   - README.md
   - SECURITY.md
   - docs/

---

**Versión:** 1.0 - Guía para Principiantes  
**Última actualización:** 26 de Octubre, 2025

**¡Disfruta tu servidor multimedia!** 🎬🍿
