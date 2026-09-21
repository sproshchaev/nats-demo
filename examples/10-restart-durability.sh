#!/usr/bin/env bash
# Пример 10. Данные потока переживают перезапуск сервера.
# Демо 2. Выполняется после примера 7.
set -e
cd "$(dirname "$0")/.."
echo "== Пример 10. Перезапуск сервера =="
echo "--- до перезапуска ---"
docker exec -i box sh -c 'nats stream report; nats consumer report ORDERS'
echo "--- перезапускаем контейнер сервера ---"
docker compose -f single/docker-compose.yml restart nats
sleep 3
echo "--- после перезапуска ---"
docker exec -i box sh -c 'nats stream report; nats consumer report ORDERS'
