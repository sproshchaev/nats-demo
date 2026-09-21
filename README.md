# nats-demo

Демонстрационный стенд к вебинару **«NATS»** курса OTUS «NoSQL» (занятие 29).

Всё работает в Docker: сам NATS, командная строка `nats` и терминал с панелями. На машину ставить
ничего не нужно, кроме Docker.

Двенадцать примеров разбиты на три демонстрации:

| Демо | Тема | Примеры | Время |
|---|---|---|---|
| 1 | Publish / Subscribe через CLI | 1–5 | ~5 мин |
| 2 | JetStream: потоки, потребители, replay | 6–10 | ~6 мин |
| 3 | NATS Cluster | 11–12 | ~4 мин |

Команды для ручного повтора — [docs/examples.md](docs/examples.md).

---

## Таблица примеров

| № | Пример | Файл | Что показывает |
|---|---|---|---|
| 1 | Рассылка всем подписчикам | `examples/01-fanout-broadcast.sh` | одно сообщение получает каждый подписчик темы |
| 2 | Маски тем | `examples/02-wildcards-subjects.sh` | `orders.*` — один уровень, `orders.>` — любое их число |
| 3 | Queue Group | `examples/03-queue-group-balance.sh` | сообщение достаётся ровно одному подписчику группы |
| 4 | Request / Reply | `examples/04-request-reply.sh` | запрос и ответ поверх обычной публикации |
| 5 | Потеря без подписчиков | `examples/05-no-subscriber-loss.sh` | базовый NATS не хранит сообщения |
| 6 | Поток сохраняет сообщения | `examples/06-stream-create.sh` | stream перехватывает публикации в свои темы |
| 7 | Потребитель и подтверждение | `examples/07-consumer-pull-ack.sh` | pull-потребитель, ack, позиция чтения на сервере |
| 8 | Повторная доставка | `examples/08-redelivery-ackwait.sh` | нет подтверждения за `ack_wait` — доставка повторяется |
| 9 | Replay с начала потока | `examples/09-replay-from-start.sh` | второй потребитель перечитывает историю |
| 10 | Перезапуск сервера | `examples/10-restart-durability.sh` | файловое хранилище переживает рестарт |
| 11 | Сообщение между узлами | `examples/11-cluster-crossnode.sh` | клиенты разных узлов кластера общаются прозрачно |
| 12 | Поток с тремя репликами | `examples/12-stream-replicas.sh` | лидер и реплики, группа RAFT |

Примеры 1–10 требуют поднятого одиночного сервера (`./up.sh`), примеры 11–12 — кластера
(`./cluster-up.sh`). Скрипты запускаются с хоста и выводят результат сразу: они же служат проверкой
стенда перед эфиром.

---

## Что внутри

```
nats-demo/
├── up.sh              запустить один сервер NATS с JetStream (примеры 1-10)
├── cluster-up.sh      запустить кластер из трёх серверов (примеры 11-12)
├── box.sh             войти в контейнер с CLI: внутри команды пишутся коротко, nats pub ...
├── down.sh            погасить всё и стереть данные JetStream
├── box/Dockerfile     образ с nats CLI и tmux
├── single/            сервер и его конфигурация для примеров 1-10
│   ├── docker-compose.yml
│   └── nats.conf
├── cluster/           три узла, у каждого свой конфиг с блоком cluster
│   ├── docker-compose.yml
│   └── n1.conf n2.conf n3.conf
├── examples/          двенадцать примеров, по файлу на каждый
├── scripts/           t3.sh — раскладка терминала на три панели, tmux.conf
└── docs/examples.md   те же примеры командами для ручного повтора
```

Версии, на которых всё проверено: NATS Server 2.11.17, NATS CLI 0.4.0, Docker 29.7.2.

---

## Быстрый старт

```bash
git clone https://github.com/sproshchaev/nats-demo.git
cd nats-demo
./up.sh                      # поднять сервер, занимает пару секунд
./box.sh                     # войти в контейнер с CLI
```

Дальше внутри контейнера:

```sh
/demo/t3.sh                  # терминал делится на три панели: два подписчика и издатель
nats pub orders.created "первое сообщение"
```

Панели переключаются мышью или сочетанием `Ctrl-b` и стрелка. Выйти из раскладки, не убивая
подписчиков, — `Ctrl-b d`, вернуться — снова `/demo/t3.sh`.

Мониторинг сервера в браузере: <http://localhost:8222> — эндпоинты `/varz`, `/connz`, `/subsz`,
`/jsz?streams=true`.

Когда всё закончено:

```bash
exit
./down.sh
```

---

## Шпаргалка команд

Подключение уже настроено переменной `NATS_URL` внутри контейнера, поэтому адрес сервера и
учётные данные в командах не пишутся.

**Основные модели**

```sh
nats sub "orders.>"                             # подписка на тему и все вложенные
nats sub "orders.>" --queue workers             # подписка в составе очереди
nats pub orders.created "текст сообщения"       # публикация
nats reply svc.price "цена заказа {{.Request}}" # сервис, отвечающий на запросы
nats request svc.price "1001"                   # запрос и ожидание ответа
```

**JetStream**

```sh
nats stream add ORDERS --subjects "orders.>" --storage file --defaults
nats stream report                              # компактная таблица по всем потокам
nats stream info ORDERS                         # подробности, включая реплики и лидера
nats stream get ORDERS 1                        # достать сообщение по номеру в потоке

nats consumer add ORDERS WORKER --pull --ack explicit --wait 5s --defaults
nats consumer next ORDERS WORKER --count 1      # забрать сообщение и подтвердить
nats consumer next ORDERS WORKER --count 1 --no-ack   # забрать и не подтверждать
nats consumer report ORDERS                     # состояние потребителей потока
```

**Проверка и диагностика**

```sh
nats server check connection                    # жив ли сервер
nats server check jetstream                     # работает ли JetStream
```

---

## Что можно попробовать самостоятельно

В двенадцать примеров эти шаги не вошли, но стенд их держит.

1. **Key-Value store.** `nats kv add CONFIG`, затем `nats kv put CONFIG rate 7.5`,
   `nats kv get CONFIG rate` и `nats kv watch CONFIG` в соседней панели.
2. **Пропускная способность.** `nats bench pub bench.subject --msgs 100000` и
   `nats bench sub bench.subject --msgs 100000` в двух панелях.
3. **Отказ узла кластера.** При поднятом кластере остановить контейнер лидера
   (`docker stop nats-n2`) и посмотреть `nats stream info ORDERS`: лидер переизбирается за секунды,
   сообщения остаются на месте. Вернуть узел — `docker start nats-n2`.
4. **Команды уровня сервера.** `nats server list` и `nats server report jetstream` требуют
   системного аккаунта. Для этого блок `authorization` в конфигурации заменяется на:

   ```
   accounts {
     SYS: { users: [ { user: sys, password: sys } ] }
     APP: { users: [ { user: demo, password: secret } ], jetstream: enabled }
   }
   system_account: SYS
   ```

   После перезапуска: `nats -s nats://sys:sys@localhost:4222 server list`.

---

## Грабли, на которые уже наступили

- **Распределение в Queue Group случайное, а не по очереди.** Если опубликовать два-три сообщения
  подряд, они вполне могут уйти одному подписчику. Разница видна на шести и более сообщениях.
- **Колонка `Redelivered` в `nats consumer report` остаётся нулевой** даже тогда, когда сообщение
  ждёт повторной доставки. Повтор виден в выводе `nats consumer next` по счётчику `tries`.
- **У `nats sub` нет тайм-аута ожидания.** Подписчик, который ничего не получает, висит до `Ctrl-C`,
  флаг `--timeout` относится к ожиданию ответов, а не к подписке.
- **`nats stream view` требует настоящего терминала.** В скриптах вместо него `nats stream get`.
- **В NATS 2.11 маршрутов между узлами больше, чем соседей**: сервер держит пул соединений.
  В `/routez` при трёх узлах видно восемь маршрутов, и это нормально.
- **Эндпоинтов `/streamz` и `/consz` не существует.** Данные о потоках и потребителях отдаёт `/jsz`
  с параметрами `streams=true` и `consumers=true`.
