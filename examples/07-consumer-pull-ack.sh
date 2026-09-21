#!/usr/bin/env bash
# Пример 7. Потребитель и подтверждение обработки.
# Демо 2. Выполняется после примера 6.
set -e
echo "== Пример 7. Pull-потребитель забирает сообщение и подтверждает его =="
docker exec -i box sh -s <<'NATS'
nats consumer rm ORDERS WORKER -f > /dev/null 2>&1
nats consumer add ORDERS WORKER --pull --ack explicit --wait 5s --defaults > /dev/null
echo "--- забираем первое сообщение ---"
nats consumer next ORDERS WORKER --count 1
echo "--- состояние потребителя ---"
nats consumer report ORDERS
NATS
