#!/usr/bin/env bash
# Погасить всё и стереть данные JetStream (возврат к чистому состоянию).
cd "$(dirname "$0")"
docker compose -f single/docker-compose.yml down -v
docker compose -f cluster/docker-compose.yml down -v
