# Dockerfile per produzione - Debian based
FROM node:18-slim AS builder

WORKDIR /app

# Installa dipendenze di sistema
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Copia file dipendenze
COPY package*.json ./
COPY prisma ./prisma/

# Installa dipendenze
RUN npm ci --only=production

# Genera Prisma client
RUN npx prisma generate

# Copia tutto il codice sorgente
COPY . .

# Compila TypeScript
RUN npm run build

# Fase finale - immagine leggera
FROM node:18-slim

WORKDIR /app

# Installa curl per healthcheck
RUN apt-get update && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*

# Copia da builder
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma

# Crea utente non-root per sicurezza
RUN groupadd -r nodejs && useradd -r -g nodejs nodejs
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:${PORT:-5000}/health || exit 1

# Porta esposta
EXPOSE 5000

# Comando avvio produzione
CMD ["npm", "start"]
