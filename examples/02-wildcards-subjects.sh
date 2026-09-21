#!/usr/bin/env bash
# Пример 2. Маски тем: звездочка против знака больше.
# Демо 1. Требуется поднятый одиночный сервер: ./up.sh
set -e
echo "== Пример 2. orders.* против orders.> =="
docker exec -i box sh -s <<'NATS'
pkill -f 'nats sub' 2>/dev/null
sleep 0.3
nats sub "orders.*" > /tmp/star.log 2>&1 &
nats sub "orders.>" > /tmp/gt.log 2>&1 &
sleep 1
nats pub orders.created "один уровень"
nats pub orders.eu.created "два уровня"
sleep 1
echo "--- подписка orders.* получила ---"; grep -c Received /tmp/star.log
grep -A1 Received /tmp/star.log
echo "--- подписка orders.> получила ---"; grep -c Received /tmp/gt.log
grep -A1 Received /tmp/gt.log
pkill -f 'nats sub'
NATS
