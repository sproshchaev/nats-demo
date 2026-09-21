#!/usr/bin/env bash
# Демо 3: поднять кластер из трёх серверов (одиночный сервер при этом гасится).
set -e
cd "$(dirname "$0")"
docker compose -f single/docker-compose.yml down >/dev/null 2>&1 || true
docker compose -f cluster/docker-compose.yml up -d --build
sleep 2
docker compose -f cluster/docker-compose.yml exec -T box nats server check connection
echo "Кластер готов. Мониторинг: http://localhost:8222 (n1), 8223 (n2), 8224 (n3)"
