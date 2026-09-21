#!/usr/bin/env bash
# Пример 12. Поток с тремя репликами: лидер и реплики.
# Демо 3. Требуется поднятый кластер: ./cluster-up.sh
set -e
echo "== Пример 12. Поток на трех узлах =="
docker exec -i box sh -s <<'NATS'
nats stream rm ORDERS -f > /dev/null 2>&1
nats stream add ORDERS --subjects "orders.>" --storage file --replicas 3 --defaults > /dev/null
nats pub orders.created "order-1" > /dev/null
nats pub orders.paid "order-1 оплачен" > /dev/null
echo "--- в колонке Replicas видны три узла, лидер со звездочкой ---"
nats stream report
echo "--- подробности по кластерной группе ---"
nats stream info ORDERS | sed -n '/Cluster Information/,/^State/p'
NATS
