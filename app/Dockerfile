# БАЗОВЫЙ ОБРАЗ — ЗЕРКАЛО AWS, НЕ Docker Hub
FROM public.ecr.aws/docker/library/node:20-alpine

WORKDIR /app

# Копируем и package.json, и lockfile
COPY package*.json ./

# Чистая инсталляция по lockfile, только прод-зависимости
RUN npm ci --omit=dev

# Копируем остальные файлы приложения
COPY src ./src
COPY public ./public

# Приложение должно слушать 80 (ECS маппит containerPort=80)
ENV PORT=80
EXPOSE 80

# Запуск Express-сервера
CMD ["node", "src/server.js"]