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
- http://localhost:8000 (Django напрямую)

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

### Структура на сервере
```text
/opt/
├── star-burger/        # Код из оригинального репозитория
└── star-burger-docker/ # Этот инфраструктурный репозиторий
```

### Настройка

1. Клонируйте оба репозитория на сервер:
```bash
cd /opt
git clone https://github.com/skislyakow/star-burger.git
git clone <ваш-инфраструктурный-репо> star-burger-docker
```

2. В `star-burger-docker` создайте `.env`:
```bash
cd star-burger-docker
cp .env.example .env
nano .env
```

Установите `DEBUG=False`, правильные `ALLOWED_HOSTS`, настройки БД.

3. Настройте внешний Nginx на сервере для проксирования на backend контейнер и раздачи статики.

### Автоматический деплой

Используйте скрипт деплоя:
```bash
./deploy/deploy.sh
```

Скрипт делает:
- `git pull` в инфраструктурном репозитории
- `git pull` в репозитории с кодом проекта (если есть)
- Сборку и запуск контейнеров
- Применение миграций
- Сборку статики
- Уведомление в Rollbar
- Перезапуск сервисов

### После перезапуска сервера
Контейнеры с `restart: always` автоматически поднимутся.

### Сохранность данных
- БД: volume `postgres_data_prod`
- Media: volume `media_data_prod`
- При `docker compose down` без `-v` данные не удаляются

## Файлы в репозитории

- `docker-compose.yaml` - запуск для разработки
- `docker/backend/Dockerfile` - образ Django
- `docker/frontend/Dockerfile` - образ для сборки фронтенда (Node.js 22 + Parcel)
- `docker/dev/nginx.dev.conf` - конфиг nginx для dev
- `docker/prod/docker-compose.yml` - конфиг для продакшена
- `deploy/deploy.sh` - скрипт автоматизации деплоя
- `.env.example` - пример переменных окружения
