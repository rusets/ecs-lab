# БАЗОВЫЙ ОБРАЗ — ЗЕРКАЛО AWS, НЕ Docker Hub
FROM public.ecr.aws/docker/library/node:20-alpine

WORKDIR /app

# Копируем и package.json, и lockfile
COPY package*.json ./

# Чистая инсталляция по lockfile, только прод-зависимости
RUN npm ci --omit=dev

# Копируем остальные файлы приложения
COPY . .

# Приложение должно слушать 80 (ECS маппит containerPort=80)
ENV PORT=80
EXPOSE 80

# Если у тебя Express-сервер (путь поправь, если другой файл)
CMD ["node", "src/server.js"]