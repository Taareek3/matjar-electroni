FROM node:22-slim

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

COPY prisma ./prisma
COPY prisma7.config.ts tsconfig.json ./
COPY src ./src

ENV NODE_ENV=production
ENV DATABASE_URL=postgresql://postgres:postgres@localhost:5432/binaflow

RUN npx prisma generate && npm run build

EXPOSE 5000

CMD ["sh", "-c", "npx prisma db push && node dist/scripts/seed.js && node dist/server.js"]
