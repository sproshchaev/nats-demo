# Демо 3. NATS Cluster

Время: около 4 минут. Слайд 27.

## Шаг 1. Поднимаем три сервера

Выходим из контейнера (`exit`) и в каталоге проекта:

```bash
./cluster-up.sh
```

Скрипт гасит одиночный сервер и поднимает три узла: `n1`, `n2`, `n3`. Занимает около шести секунд.

## Шаг 2. Смотрим конфигурацию узла

```bash
cat cluster/n1.conf
```

```
server_name: n1
port: 4222
http_port: 8222

jetstream {
  store_dir: /data/jetstream
}

cluster {
  name: nats-demo-cluster
  port: 6222
  routes: [
    nats://n2:6222
    nats://n3:6222
  ]
}
```

Это тот самый конфиг со слайда 14: имя узла, клиентский порт, имя кластера, кластерный порт 6222 и
список соседей. У `n2` и `n3` файлы отличаются только именем и списком в `routes`.

## Шаг 3. Сообщение проходит между узлами

```bash
./box.sh
/demo/t3.sh
```

В панели `SUB A` подписываемся на узле `n3`:

```sh
nats -s nats://demo:secret@n3:4222 sub "orders.>"
```

В панели `PUB` публикуем на узле `n1`, он задан переменной `NATS_URL`:

```sh
nats pub orders.created "привет из n1"
```

Сообщение приходит подписчику `n3`. Клиенты подключены к разным серверам и об этом не знают.

## Шаг 4. Поток с тремя репликами

```sh
nats stream add ORDERS --subjects "orders.>" --storage file --replicas 3 --defaults
nats pub orders.created "order-1"
nats pub orders.paid "order-1 оплачен"
nats stream report
```

В колонке `Replicas` видны все три узла, звёздочкой отмечен лидер:

```
│ Stream │ Storage │ Consumers │ Messages │ Bytes │ Replicas    │
│ ORDERS │ File    │ 0         │ 2        │ 114 B │ n1, n2*, n3 │
```

Подробности — в конце вывода `nats stream info ORDERS`:

```
Cluster Information:
                         Name: nats-demo-cluster
                       Leader: n2 (68ms)
                      Replica: n1, current, seen 32ms ago
                      Replica: n3, current, seen 32ms ago
```

`current` означает, что реплика не отстаёт от лидера. Это и есть группа RAFT со слайда 19.

## Шаг 5. Мониторинг кластера

В браузере: <http://localhost:8222/routez> — маршруты узла `n1`. У каждого узла свой порт
мониторинга: 8222 у `n1`, 8223 у `n2`, 8224 у `n3`.

Маршрутов в выводе больше, чем соседей: начиная с версии 2.10 сервер держит пул соединений к
каждому соседу. Соседи различаются по полю `remote_name`.

## После эфира

```bash
exit
./down.sh
```
