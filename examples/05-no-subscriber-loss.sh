#!/usr/bin/env bash
# Пример 5. Без подписчиков сообщение теряется.
# Демо 1. Требуется поднятый одиночный сервер: ./up.sh
set -e
echo "== Пример 5. Core NATS не хранит сообщения =="
docker exec -i box sh -s <<'NATS'
pkill -f 'nats.*sub' 2>/dev/null || true
sleep 0.3
echo "--- публикуем, когда подписчиков нет ---"
nats pub orders.created "это сообщение никто не ждет"
echo "--- поднимаем подписчика после публикации, ждем 3 секунды ---"
nats sub "orders.>" > /tmp/late.log 2>&1 &
sleep 3
pkill -f 'nats.*sub' 2>/dev/null || true
sleep 0.3
echo "--- что он получил ---"
n=$(grep -c Received /tmp/late.log || true)
echo "получено сообщений: $n - опоздавший подписчик не получит ничего"
NATS
