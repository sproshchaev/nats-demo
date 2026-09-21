#!/usr/bin/env bash
# Пример 6. Поток JetStream сохраняет сообщения.
# Демо 2. Требуется поднятый одиночный сервер: ./up.sh
set -e
echo "== Пример 6. Создаем поток и публикуем в него =="
docker exec -i box sh -s <<'NATS'
nats stream rm ORDERS -f > /dev/null 2>&1
nats stream add ORDERS --subjects "orders.>" --storage file --defaults
echo "--- публикуем три сообщения ---"
nats pub orders.created "order-1"
nats pub orders.created "order-2"
nats pub orders.paid "order-1 оплачен"
echo "--- отчет по потокам ---"
nats stream report
NATS
