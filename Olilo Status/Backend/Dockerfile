FROM node:22-alpine

WORKDIR /app

# Install dependencies first to leverage Docker layer caching.
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY src ./src

ENV NODE_ENV=production
EXPOSE 3000

CMD ["node", "src/index.js"]
