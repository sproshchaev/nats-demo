#!/usr/bin/env bash
# Пример 9. Replay: новый потребитель читает поток с начала.
# Демо 2. Выполняется после примера 6.
set -e
echo "== Пример 9. Перечитывание потока с первого сообщения =="
docker exec -i box sh -s <<'NATS'
nats consumer rm ORDERS REPLAY -f > /dev/null 2>&1
nats consumer add ORDERS REPLAY --pull --ack none --deliver all --defaults > /dev/null
echo "--- новый потребитель получает все сообщения потока ---"
nats consumer next ORDERS REPLAY --count 3
NATS
