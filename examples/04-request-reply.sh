#!/usr/bin/env bash
# Пример 4. Request / Reply: запрос и ответ.
# Демо 1. Требуется поднятый одиночный сервер: ./up.sh
set -e
echo "== Пример 4. Запрос и ответ =="
docker exec -i box sh -s <<'NATS'
pkill -f 'nats reply' 2>/dev/null
sleep 0.3
nats reply svc.price "цена заказа {{.Request}}: 250 руб" > /tmp/reply.log 2>&1 &
sleep 1
nats request svc.price "1001"
echo "--- что видел сервис-ответчик ---"; cat /tmp/reply.log
pkill -f 'nats reply'
NATS
