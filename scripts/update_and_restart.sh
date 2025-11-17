#!/usr/bin/env bash
set -euo pipefail

# Script to update repo, pull images, and restart docker compose
echo "Updating repository and pulling images..."
git pull origin main
docker compose pull

echo "Restarting docker compose..."
docker compose up -d

echo "Done. Check containers with: docker ps"
