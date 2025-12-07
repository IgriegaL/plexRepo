# 📸 Immich Setup Guide

Immich is a self-hosted photo and video management solution integrated into your stack.

## 🚀 Quick Start

### 1. **Update your `.env` file** (if not already done)

Make sure these variables are set in your `.env`:

```bash
# Immich Photo/Video Management
IMMICH_VERSION=release
IMMICH_DB_PASSWORD=immichpassword        # Change this to a strong password!
IMMICH_DB_USERNAME=immich
IMMICH_DB_DATABASE_NAME=immich
IMMICH_UPLOADS_VOLUME=/mnt/DiscoDuro/immich/uploads
IMMICH_DB_DATA_LOCATION=/mnt/nvme/docker-volumes/immich-postgres
```

### 2. **Create required directories**

```bash
# If not already created during main setup
sudo mkdir -p /mnt/nvme/docker-volumes/immich-postgres
sudo mkdir -p /mnt/DiscoDuro/immich/uploads
sudo chown -R 1000:1000 /mnt/nvme/docker-volumes /mnt/DiscoDuro
```

### 3. **Start Immich services**

```bash
docker compose up -d immich-server immich-machine-learning immich-postgres immich-redis
```

### 4. **Access Immich**

Open your browser and navigate to:
```
http://<your-server-ip>:2283
```

## 🔧 First Time Setup

1. **Create Admin Account:**
   - When you first access Immich, you'll be prompted to create an admin account
   - Set a strong password

2. **Upload Photos/Videos:**
   - Use the web interface to upload photos and videos
   - Or use the Immich mobile app (iOS/Android) for automatic uploads

3. **Configure Machine Learning (Optional):**
   - Immich includes optional ML features for:
     - Face detection and recognition
     - Object detection
     - Reverse geocoding
   - These are handled by the `immich-machine-learning` service

## 📊 Service Architecture

| Service | Purpose | Port |
| :--- | :--- | :--- |
| `immich-server` | Main API server | 2283 |
| `immich-machine-learning` | ML features | Internal |
| `immich-postgres` | Database | Internal |
| `immich-redis` | Cache | Internal |

## 🗂️ Storage Layout

```
/mnt/DiscoDuro/immich/
├── uploads/          # All photos/videos stored here
│   ├── library/     # Original files
│   └── thumbs/      # Thumbnails and previews
```

```
/mnt/nvme/docker-volumes/immich-postgres/
└── PostgreSQL database files (fast storage recommended)
```

## 🔄 Backup & Restore

### Backup
```bash
# Backup database
docker exec immich_postgres pg_dump -U immich immich > immich_backup.sql

# Backup uploads (if needed)
tar czf immich_uploads.tar.gz /mnt/DiscoDuro/immich/uploads/
```

### Restore
```bash
# Restore database
docker exec -i immich_postgres psql -U immich immich < immich_backup.sql

# Restore uploads
tar xzf immich_uploads.tar.gz -C /
```

## 🚀 Performance Tuning

For Orange Pi 5 Pro (RK3588):

1. **Enable Hardware Acceleration (Optional):**
   - Immich supports RKMPP for RK3588
   - Uncomment the extends section in `docker-compose.yml` for ML acceleration

2. **Memory Limits:**
   - `immich-server`: 2GB (set in docker-compose.yml)
   - `immich-machine-learning`: 1.5GB
   - `immich-postgres`: 500MB
   - Adjust based on your system's available RAM

3. **Database:**
   - Ensure PostgreSQL is on fast NVMe storage
   - Consider enabling `DB_STORAGE_TYPE: 'HDD'` if on spinning drives

## 🔐 Security Tips

1. **Strong Database Password:**
   ```bash
   # Generate a secure password
   openssl rand -base64 32
   ```

2. **Change Default Credentials:**
   - Always set a strong admin password during first setup

3. **Network Security:**
   - Use a reverse proxy (Nginx, Traefik) for HTTPS if exposing externally
   - Keep Immich on the internal network by default

## 🐛 Troubleshooting

### Immich not starting
```bash
# Check logs
docker logs immich_server
docker logs immich_postgres
```

### Database connection errors
```bash
# Verify PostgreSQL is running
docker ps | grep immich_postgres

# Check database initialization
docker logs immich_postgres
```

### Slow performance
- Check available disk space
- Monitor CPU/Memory usage
- Verify NVMe is being used for database

## 📚 Additional Resources

- [Official Immich Docs](https://docs.immich.app/)
- [Immich Docker Setup Guide](https://docs.immich.app/install/docker-compose/)
- [Community Forum](https://github.com/immich-app/immich/discussions)

---

**Integrated with:** 🍊 Plex Media Server Stack for Orange Pi 5 Pro
