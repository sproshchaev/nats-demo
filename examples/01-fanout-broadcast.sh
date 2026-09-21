#!/usr/bin/env bash
# Пример 1. Рассылка всем подписчикам (fan-out).
# Демо 1. Требуется поднятый одиночный сервер: ./up.sh
set -e
echo "== Пример 1. Одно сообщение получают все подписчики =="
docker exec -i box sh -s <<'NATS'
pkill -f 'nats.*sub' 2>/dev/null || true
sleep 0.3
nats sub "orders.>" > /tmp/subA.log 2>&1 &
nats sub "orders.>" > /tmp/subB.log 2>&1 &
sleep 1
nats pub orders.created '{"id":1001,"sum":250}'
sleep 1
echo "--- панель SUB A ---"; grep -A1 Received /tmp/subA.log
echo "--- панель SUB B ---"; grep -A1 Received /tmp/subB.log
pkill -f 'nats.*sub' 2>/dev/null || true
NATS
