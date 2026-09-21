#!/usr/bin/env bash
# Войти в контейнер с NATS CLI. Внутри команды пишутся коротко: nats pub, nats sub, ...
cd "$(dirname "$0")"
f=single/docker-compose.yml
docker ps --format '{{.Names}}' | grep -q '^nats-n1$' && f=cluster/docker-compose.yml
exec docker compose -f "$f" exec box sh
