#!/bin/bash

set -e

export PATH="$HOME/.local/bin:$PATH"

echo "=== Star Burger Docker Deploy ==="

PROJECT_DIR="/opt/star-burger-docker"
APP_DIR="/opt/star-burger"
COMPOSE="docker compose --project-directory $PROJECT_DIR -f $PROJECT_DIR/docker/prod/docker-compose.yml"

cd "$PROJECT_DIR"

echo "=== Pulling latest infra changes ==="
git pull

if [ -d "$APP_DIR" ]; then
    echo "=== Pulling latest app changes ==="
    cd "$APP_DIR" && git pull && cd "$PROJECT_DIR"
fi

echo "=== Stopping legacy non-docker service if present ==="
if systemctl list-unit-files star-burger.service >/dev/null 2>&1; then
    systemctl stop star-burger.service || true
    systemctl disable star-burger.service || true
fi

echo "=== Stopping any leftover dev compose stack ==="
docker compose --project-directory "$PROJECT_DIR" -f "$PROJECT_DIR/docker-compose.yaml" down --remove-orphans || true

echo "=== Building images and starting containers ==="
$COMPOSE down --remove-orphans || true
$COMPOSE up -d --build db frontend-builder backend

echo "=== Waiting for backend to be ready ==="
sleep 15

echo "=== Running migrations ==="
$COMPOSE exec -T backend python manage.py migrate --noinput

echo "=== Collecting static files ==="
$COMPOSE run --rm static_collector

echo "=== Reloading host nginx ==="
nginx -t && systemctl reload nginx

echo "=== Notifying Rollbar ==="
if [ -f .env ]; then
    ROLLBAR_TOKEN=$(grep '^ROLLBAR_TOKEN=' .env | cut -d= -f2)
    ROLLBAR_ENVIRONMENT=$(grep '^ROLLBAR_ENVIRONMENT=' .env | cut -d= -f2)
    REVISION=$(git -C "$APP_DIR" rev-parse HEAD 2>/dev/null || git rev-parse HEAD)

    if [ -n "$ROLLBAR_TOKEN" ]; then
        curl -sS https://api.rollbar.com/api/1/deploy/ \
          -F access_token="$ROLLBAR_TOKEN" \
          -F environment="$ROLLBAR_ENVIRONMENT" \
          -F revision="$REVISION" \
          -F local_username="$(whoami)" > /dev/null || true
    fi
fi

echo "=== Deploy completed successfully ==="
$COMPOSE ps
