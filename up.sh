#!/usr/bin/env bash
# Демо 1 и 2: поднять один сервер NATS с JetStream.
set -e
cd "$(dirname "$0")"
docker compose -f cluster/docker-compose.yml down -v >/dev/null 2>&1 || true
docker compose -f single/docker-compose.yml up -d --build
docker compose -f single/docker-compose.yml exec -T box nats server check connection
echo "Сервер готов. Мониторинг: http://localhost:8222"
