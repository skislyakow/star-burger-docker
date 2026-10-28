#!/bin/bash

set -e

export PATH="$HOME/.local/bin:$PATH"

echo "=== Star Burger Docker Deploy ==="

PROJECT_DIR="/opt/star-burger-docker"
APP_DIR="/opt/star-burger"

cd $PROJECT_DIR

echo "=== Pulling latest infra changes ==="
git pull

if [ -d "$APP_DIR" ]; then
    echo "=== Pulling latest app changes ==="
    cd $APP_DIR && git pull && cd $PROJECT_DIR
fi

echo "=== Building images and starting containers ==="
docker compose -f docker/prod/docker-compose.yml down
docker compose -f docker/prod/docker-compose.yml up -d --build

echo "=== Waiting for containers to be ready ==="
sleep 10

echo "=== Running migrations ==="
docker compose -f docker/prod/docker-compose.yml exec -T backend python manage.py migrate --noinput

echo "=== Collecting static files ==="
docker compose -f docker/prod/docker-compose.yml run --rm static_collector

echo "=== Restarting backend ==="
docker compose -f docker/prod/docker-compose.yml restart backend

echo "=== Notifying Rollbar ==="
if [ -f .env ]; then
    ROLLBAR_TOKEN=$(grep '^ROLLBAR_TOKEN=' .env | cut -d= -f2)
    ROLLBAR_ENVIRONMENT=$(grep '^ROLLBAR_ENVIRONMENT=' .env | cut -d= -f2)
    REVISION=$(git -C $APP_DIR rev-parse HEAD 2>/dev/null || git rev-parse HEAD)
    
    if [ ! -z "$ROLLBAR_TOKEN" ]; then
        curl -sS https://api.rollbar.com/api/1/deploy/ \
          -F access_token=$ROLLBAR_TOKEN \
          -F environment=$ROLLBAR_ENVIRONMENT \
          -F revision=$REVISION \
          -F local_username=$(whoami) > /dev/null || true
    fi
fi

echo "=== Deploy completed successfully ==="
