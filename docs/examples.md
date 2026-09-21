# Двенадцать примеров

Команды для ручного повтора. Каждый пример можно набрать самому, а можно запустить готовым
скриптом с хоста — имя скрипта указано в заголовке.

Подготовка для примеров 1–10:

```bash
./up.sh          # поднять сервер
./box.sh         # войти в контейнер с CLI
/demo/t3.sh      # три панели: SUB A, SUB B, PUB
```

Панели переключаются мышью или `Ctrl-b` со стрелкой.

---

## Демо 1. Publish / Subscribe через CLI

### 1. Рассылка всем подписчикам — `examples/01-fanout-broadcast.sh`

В панелях `SUB A` и `SUB B`:

```sh
nats sub "orders.>"
```

В панели `PUB`:

```sh
nats pub orders.created '{"id":1001,"sum":250}'
```

Сообщение приходит в обе верхние панели: копию получает каждый подписчик.

### 2. Маски тем — `examples/02-wildcards-subjects.sh`

`SUB A`: `nats sub "orders.*"` · `SUB B`: `nats sub "orders.>"`

```sh
nats pub orders.created "один уровень"
nats pub orders.eu.created "два уровня"
```

Звёздочка заменяет ровно один уровень темы, знак «больше» — любое их число. Первый подписчик
получит одно сообщение, второй оба.

### 3. Queue Group — `examples/03-queue-group-balance.sh`

В обеих верхних панелях:

```sh
nats sub "orders.>" --queue workers
```

В панели `PUB`:

```sh
for i in 1 2 3 4 5 6; do nats pub orders.created "order-$i"; sleep 1; done
```

Каждое сообщение достаётся ровно одному подписчику. Распределение случайное, а не по очереди.

### 4. Request / Reply — `examples/04-request-reply.sh`

В `SUB B`:

```sh
nats reply svc.price "цена заказа {{.Request}}: 250 руб"
```

В `PUB`:

```sh
nats request svc.price "1001"
```

Ответ возвращается тому, кто спрашивал: клиент передал вместе с запросом уникальную тему для ответа.

### 5. Без подписчиков сообщение исчезает — `examples/05-no-subscriber-loss.sh`

Гасим подписчиков, затем в `PUB`:

```sh
nats pub orders.created "это сообщение никто не ждёт"
```

Поднимаем подписчика после публикации — он не получит ничего. Базовый NATS доставляет только тем,
кто подключён сейчас.

---

## Демо 2. JetStream: потоки, потребители, replay

### 6. Поток сохраняет сообщения — `examples/06-stream-create.sh`

```sh
nats stream add ORDERS --subjects "orders.>" --storage file --defaults
nats pub orders.created "order-1"
nats pub orders.created "order-2"
nats pub orders.paid "order-1 оплачен"
nats stream report
```

В отчёте три сообщения. Команды издателя не изменились: поток подключается на стороне сервера.

### 7. Потребитель и подтверждение — `examples/07-consumer-pull-ack.sh`

```sh
nats consumer add ORDERS WORKER --pull --ack explicit --wait 5s --defaults
nats consumer next ORDERS WORKER --count 1
nats consumer report ORDERS
```

Сообщение приходит и подтверждается, позицию чтения хранит сервер.

### 8. Повторная доставка — `examples/08-redelivery-ackwait.sh`

```sh
nats consumer next ORDERS WORKER --count 1 --no-ack
nats consumer report ORDERS      # Ack Pending: 1
sleep 6
nats consumer next ORDERS WORKER --count 1
```

Приходит то же сообщение с `tries: 2`: подтверждения сервер не дождался. Гарантия «хотя бы один раз».

### 9. Replay с начала потока — `examples/09-replay-from-start.sh`

```sh
nats consumer add ORDERS REPLAY --pull --ack none --deliver all --defaults
nats consumer next ORDERS REPLAY --count 3
```

Новый потребитель читает все сообщения, включая уже обработанные первым. Позиции независимы.

### 10. Данные переживают перезапуск — `examples/10-restart-durability.sh`

На хосте:

```bash
docker compose -f single/docker-compose.yml restart nats
```

После старта `nats stream report` и `nats consumer report ORDERS` показывают те же цифры: хранилище
файловое.

---

## Демо 3. NATS Cluster

Подготовка:

```bash
./cluster-up.sh    # гасит одиночный сервер и поднимает три узла
./box.sh
/demo/t3.sh
```

### 11. Сообщение проходит между узлами — `examples/11-cluster-crossnode.sh`

В `SUB A`:

```sh
nats -s nats://demo:secret@n3:4222 sub "orders.>"
```

В `PUB` (подключение по умолчанию — узел `n1`):

```sh
nats pub orders.created "привет из n1"
```

Клиенты подключены к разным серверам и об этом не знают.

### 12. Поток с тремя репликами — `examples/12-stream-replicas.sh`

```sh
nats stream add ORDERS --subjects "orders.>" --storage file --replicas 3 --defaults
nats pub orders.created "order-1"
nats stream report
nats stream info ORDERS
```

В колонке `Replicas` три узла, звёздочкой отмечен лидер. Подробности о группе RAFT — в блоке
`Cluster Information` вывода `nats stream info`.

---

После демонстраций:

```bash
exit
./down.sh
```
