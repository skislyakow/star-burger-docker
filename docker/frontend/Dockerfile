FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone https://github.com/skislyakow/star-burger.git .

RUN npm ci --no-audit --no-fund

RUN npm run build
