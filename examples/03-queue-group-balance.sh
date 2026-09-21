#!/usr/bin/env bash
# Пример 3. Queue Group: балансировка между подписчиками.
# Демо 1. Требуется поднятый одиночный сервер: ./up.sh
set -e
echo "== Пример 3. Каждое сообщение достается одному подписчику =="
docker exec -i box sh -s <<'NATS'
pkill -f 'nats sub' 2>/dev/null
sleep 0.3
nats sub "orders.>" --queue workers > /tmp/w1.log 2>&1 &
nats sub "orders.>" --queue workers > /tmp/w2.log 2>&1 &
sleep 1
for i in 1 2 3 4 5 6; do nats pub orders.created "order-$i" > /dev/null; sleep 1; done
sleep 1
echo "worker 1 получил: $(grep -c Received /tmp/w1.log) | $(grep -h '^order-' /tmp/w1.log | tr '\n' ' ')"
echo "worker 2 получил: $(grep -c Received /tmp/w2.log) | $(grep -h '^order-' /tmp/w2.log | tr '\n' ' ')"
echo "всего отправлено: 6, дублей нет"
pkill -f 'nats sub'
NATS
