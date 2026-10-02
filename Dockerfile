FROM node:22-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 make g++ \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

COPY prisma ./prisma
COPY prisma7.config.ts tsconfig.json ./
COPY src ./src

ENV NODE_ENV=production
ENV DATABASE_URL=file:./dev.db

RUN npx prisma generate && npm run build

EXPOSE 5000

CMD ["sh", "-c", "npx prisma db push && node dist/scripts/seed.js && node dist/server.js"]
