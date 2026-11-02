FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git init && \
    git remote add origin https://github.com/skislyakow/star-burger.git && \
    git fetch --depth=1 origin main && \
    git checkout origin/main -- package.json package-lock.json

RUN npm ci --no-audit --no-fund

RUN git checkout origin/main

RUN npm run build
