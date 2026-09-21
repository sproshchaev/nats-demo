# Демо 2. JetStream: потоки, потребители, replay

Время: около 6 минут. Слайд 26.

Продолжаем в той же раскладке. Работаем в нижней панели `PUB`, верхние панели свободны.

## Шаг 1. Создаём поток

```sh
nats stream add ORDERS --subjects "orders.>" --storage file --defaults
```

Флаг `--defaults` берёт значения по умолчанию для всего, что мы не указали: политика хранения
`Limits`, лимиты не заданы, одна реплика.

## Шаг 2. Те же публикации, но теперь они сохраняются

```sh
nats pub orders.created "order-1"
nats pub orders.created "order-2"
nats pub orders.paid "order-1 оплачен"
nats stream report
```

Таблица показывает, что в потоке три сообщения:

```
│ Stream │ Storage │ Consumers │ Messages │ Bytes │
│ ORDERS │ File    │ 0         │ 3        │ 165 B │
```

Отправитель ничего не менял в командах: он по-прежнему публикует в `orders.*`, а поток перехватывает
и записывает.

## Шаг 3. Потребитель и подтверждение

```sh
nats consumer add ORDERS WORKER --pull --ack explicit --wait 5s --defaults
nats consumer next ORDERS WORKER --count 1
```

Приходит первое сообщение и подтверждается:

```
[14:42:40] subj: orders.created / tries: 1 / cons seq: 1 / str seq: 1 / pending: 2
order-1
Acknowledged message
```

## Шаг 4. Повторная доставка

Забираем следующее сообщение и подтверждение не отправляем:

```sh
nats consumer next ORDERS WORKER --count 1 --no-ack
nats consumer report ORDERS
```

В отчёте видно неподтверждённое сообщение: `Ack Pending: 1`.

Ждём больше пяти секунд, то есть заданного `--wait 5s`, и тянем снова:

```sh
nats consumer next ORDERS WORKER --count 1
```

Приходит то же самое сообщение, и счётчик попыток вырос:

```
[14:42:55] subj: orders.created / tries: 2 / cons seq: 3 / str seq: 2 / pending: 1
order-2
```

Колонка `Redelivered` в отчёте при этом остаётся нулевой, повтор виден именно по `tries`.

## Шаг 5. Replay: читаем поток с начала

```sh
nats consumer add ORDERS REPLAY --pull --ack none --deliver all --defaults
nats consumer next ORDERS REPLAY --count 3
```

Новый потребитель получает все три сообщения с первого. Данные в потоке лежат независимо от того,
кто и сколько раз их уже читал.

## Шаг 6. Перезапуск сервера (если позволяет время)

В отдельном окне терминала:

```bash
docker compose -f single/docker-compose.yml restart nats
```

После перезапуска:

```sh
nats stream report
nats consumer report ORDERS
```

Сообщения на месте, позиция потребителя тоже: хранилище файловое.

В браузере по адресу <http://localhost:8222/jsz?streams=true> тот же поток виден в JSON — это
эндпоинт со слайда 24.
