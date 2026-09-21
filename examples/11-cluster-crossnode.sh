#!/usr/bin/env bash
# Пример 11. Сообщение проходит между узлами кластера.
# Демо 3. Требуется поднятый кластер: ./cluster-up.sh
set -e
echo "== Пример 11. Подписчик на n3, издатель на n1 =="
docker exec -i box sh -s <<'NATS'
pkill -f 'nats.*sub' 2>/dev/null || true
sleep 0.3
nats -s nats://demo:secret@n3:4222 sub "orders.>" > /tmp/n3.log 2>&1 &
sleep 1
echo "--- публикуем на узле n1 ---"
nats pub orders.created "привет из n1"
sleep 1
echo "--- что получил подписчик узла n3 ---"
grep -A1 Received /tmp/n3.log
pkill -f 'nats.*sub' 2>/dev/null || true
NATS
