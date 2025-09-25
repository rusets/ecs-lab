FROM public.ecr.aws/docker/library/node:20-alpine
WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src
# (опционально) COPY public ./public

ENV PORT=80
EXPOSE 80
CMD ["node", "src/server.js"]