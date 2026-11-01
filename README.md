# Star Burger Docker

Инфраструктурный репозиторий для докеризации проекта [star-burger](https://github.com/skislyakow/star-burger).

## Суть подхода

Код проекта хранится в отдельном репозитории. Dockerfile'ы в этом репозитории собирают образы напрямую из оригинального репозитория через `build.context`.

## Локальный запуск (разработка)

### Требования
- Docker
- Docker Compose

### Инструкция

1. Склонируйте инфраструктурный репозиторий:
```bash
git clone <repo-url> star-burger-docker
cd star-burger-docker
```

2. Скопируйте `.env.example` в `.env` и заполните переменные:
```bash
cp .env.example .env
```

3. Запустите проект:
```bash
docker compose up --build
```

При первом запуске Docker подтянет код из https://github.com/skislyakow/star-burger.git и соберёт образы.

4. Проект будет доступен по адресу:
- http://localhost (через nginx)

5. Создайте суперпользователя:
```bash
docker compose exec backend python manage.py createsuperuser
```

6. Остановка:
```bash
docker compose down
```

Файлы в `media/` сохраняются в volume. Данные БД сохраняются в volume при перезапуске контейнеров.

## Деплой на сервер

Сайт полностью докеризирован. Весь стек поднимается через **Docker Compose** из `docker/prod/docker-compose.yml`. Бэкенд, фронтенд, БД и Nginx — **отдельные контейнеры** (в разных сервисах docker-compose).

### Структура на сервере
```text
/opt/
└── star-burger-docker/ # Инфраструктурный репозиторий
```

Dockerfile'ы этого репозитория сами клонируют оригинальный код из [star-burger](https://github.com/skislyakow/star-burger.git), поэтому второй репозиторий на сервере не обязателен.

### Настройка

1. Клонируйте инфраструктурный репозиторий на сервер:
```bash
cd /opt
git clone <ваш-инфраструктурный-репо> star-burger-docker
```

2. В `star-burger-docker` создайте `.env`:
```bash
cd star-burger-docker
cp .env.example .env
nano .env
```

Установите `DEBUG=False`, правильные `ALLOWED_HOSTS`, настройки БД.

3. Настройте внешний Nginx на сервере по образцу `docker/prod/nginx.host.conf.example`:
   - `proxy_pass http://127.0.0.1:8002;`
   - `/static/` → `/opt/star-burger-docker/staticfiles/`
   - `/media/` → `/opt/star-burger-docker/media/`

### Автоматический деплой

Используйте скрипт деплоя:
```bash
./deploy/deploy.sh
```

Скрипт делает:
- `git pull` в инфраструктурном репозитории
- Сборку образов через `docker compose build`
- Запуск контейнеров через `docker compose up -d`
- Применение миграций
- Сборку статики
- Уведомление в Rollbar

### Автовосстановление после перезапуска сервера
Docker включён в автозагрузку, у всех сервисов в прод-конфиге `restart: always`. После перезагрузки сервера контейнеры поднимутся автоматически.

### Сохранность данных
- **БД** хранится в named volume `postgres_data_prod`
- **Media-файлы** хранятся в named volume `media_data_prod`
- Если удалять и пересоздавать контейнеры **без** флага `-v` (`docker compose down` без `-v`), volumes сохраняются — данные в БД и каталоге `media/` **не теряются**.

## Файлы в репозитории

- `docker-compose.yaml` - запуск для разработки
- `docker/backend/Dockerfile` - образ Django
- `docker/frontend/Dockerfile` - образ для сборки фронтенда (Node.js 22 + Parcel)
- `docker/dev/nginx.dev.conf` - конфиг nginx для dev
- `docker/prod/docker-compose.yml` - конфиг для продакшена
- `deploy/deploy.sh` - скрипт автоматизации деплоя
- `.env.example` - пример переменных окружения
