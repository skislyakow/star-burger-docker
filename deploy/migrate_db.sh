#!/bin/bash
set -e

echo "=== Dump old host DB ==="
sudo -u postgres pg_dump -Fc starburger > /tmp/starburger_old.dump
ls -lh /tmp/starburger_old.dump

echo "=== Restore into docker DB ==="
docker cp /tmp/starburger_old.dump star-burger-docker-db-1:/tmp/starburger_old.dump
docker exec star-burger-docker-db-1 pg_restore -U starburger -d starburger --clean --if-exists /tmp/starburger_old.dump || true

echo "=== Product counts ==="
echo -n "old host: "
sudo -u postgres psql -d starburger -tAc 'select count(*) from foodcartapp_product'
echo -n "docker: "
docker exec star-burger-docker-db-1 psql -U starburger -d starburger -tAc 'select count(*) from foodcartapp_product'

rm -f /tmp/starburger_old.dump
echo "=== Done ==="
