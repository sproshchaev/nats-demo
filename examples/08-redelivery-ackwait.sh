#!/usr/bin/env bash
# Пример 8. Повторная доставка неподтвержденного сообщения.
# Демо 2. Выполняется после примера 7.
set -e
echo "== Пример 8. Нет подтверждения - сервер доставит снова =="
docker exec -i box sh -s <<'NATS'
echo "--- забираем сообщение и НЕ подтверждаем ---"
nats consumer next ORDERS WORKER --count 1 --no-ack
echo "--- в отчете оно висит неподтвержденным: Ack Pending 1 ---"
nats consumer report ORDERS
echo "--- ждем 6 секунд, ack wait равен 5 секундам ---"
sleep 6
echo "--- тянем снова: то же сообщение, tries стал 2 ---"
nats consumer next ORDERS WORKER --count 1
NATS
