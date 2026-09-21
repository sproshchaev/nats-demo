# nats-demo

Демонстрационный стенд к вебинару **«NATS»** курса OTUS «NoSQL» (занятие 29).

Всё работает в Docker: сам NATS, командная строка `nats` и терминал с панелями. На машину ставить
ничего не нужно, кроме Docker.

| Демо | Тема | Что показываем | Время |
|---|---|---|---|
| 1 | Publish / Subscribe через CLI | рассылка всем подписчикам, очередь Queue Group, запрос-ответ, потеря сообщения без подписчиков | ~5 мин |
| 2 | JetStream: потоки, потребители, replay | поток хранит сообщения, подтверждения и повторная доставка, перечитывание с начала | ~6 мин |
| 3 | NATS Cluster | три сервера из десятка строк конфига, сообщение между узлами, поток с тремя репликами | ~4 мин |

Подробные сценарии: [docs/demo1.md](docs/demo1.md) · [docs/demo2.md](docs/demo2.md) · [docs/demo3.md](docs/demo3.md)

---

## Что внутри

```
nats-demo/
├── up.sh              запустить один сервер NATS с JetStream (демо 1 и 2)
├── cluster-up.sh      запустить кластер из трёх серверов (демо 3)
├── box.sh             войти в контейнер с CLI: внутри команды пишутся коротко, nats pub ...
├── down.sh            погасить всё и стереть данные JetStream
├── box/Dockerfile     образ с nats CLI и tmux
├── single/            сервер и его конфигурация для демо 1 и 2
├── cluster/           три узла, у каждого свой конфиг с блоком cluster
├── scripts/           t3.sh — раскладка терминала на три панели, tmux.conf
└── docs/              сценарии демонстраций по шагам
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

На вебинар эти шаги не вошли, но стенд их держит.

1. **Маски тем.** Запустить подписчиков на `orders.*` и `orders.>` одновременно и опубликовать
   в `orders.created` и `orders.eu.created`. Первая маска заменяет ровно один уровень, вторая —
   любое число уровней.
2. **Key-Value store.** `nats kv add CONFIG`, затем `nats kv put CONFIG rate 7.5`,
   `nats kv get CONFIG rate` и `nats kv watch CONFIG` в соседней панели.
3. **Пропускная способность.** `nats bench pub bench.subject --msgs 100000` и
   `nats bench sub bench.subject --msgs 100000` в двух панелях.
4. **Отказ узла кластера.** При поднятом кластере остановить контейнер лидера
   (`docker stop nats-n2`) и посмотреть `nats stream info ORDERS`: лидер переизбирается за секунды,
   сообщения остаются на месте. Вернуть узел — `docker start nats-n2`.
5. **Команды уровня сервера.** `nats server list` и `nats server report jetstream` требуют
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
- **В NATS 2.11 маршрутов между узлами больше, чем соседей**: сервер держит пул соединений.
  В `/routez` при трёх узлах видно восемь маршрутов, и это нормально.
- **Эндпоинтов `/streamz` и `/consz` не существует.** Данные о потоках и потребителях отдаёт `/jsz`
  с параметрами `streams=true` и `consumers=true`.
