FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/app/.venv/bin:/root/.local/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    libpq-dev \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

WORKDIR /app

RUN git init && \
    git remote add origin https://github.com/skislyakow/star-burger.git && \
    git fetch --depth=1 origin main && \
    git checkout origin/main -- pyproject.toml uv.lock

RUN uv sync --frozen --no-dev

RUN git checkout origin/main

EXPOSE 8000

CMD ["gunicorn", "star_burger.wsgi:application", "--bind", "0.0.0.0:8000"]
