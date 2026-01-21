#!/bin/bash

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 AVVIO INTELLIGENTE ORSOCOOK${NC}"
echo "======================================"

# Funzioni di utilità
check_service() {
  docker ps --format '{{.Names}}' | grep -q "^$1\$"
  return $?
}

start_service() {
  echo -e "${YELLOW}▶️  Avvio $1...${NC}"
  docker-compose up -d $1
  
  # Attesa intelligente basata sul servizio
  case $1 in
    "ricette-minio")
      echo -n "⏳ Attendo MinIO..."
      for i in {1..10}; do
        if curl -s http://localhost:9000/minio/health/live >/dev/null 2>&1; then
          echo -e "${GREEN} ✅${NC}"
          break
        fi
        sleep 2
        echo -n "."
      done
      ;;
    "ricette-db")
      echo -n "⏳ Attendo PostgreSQL..."
      for i in {1..10}; do
        if docker exec ricette-db pg_isready -U postgres >/dev/null 2>&1; then
          echo -e "${GREEN} ✅${NC}"
          break
        fi
        sleep 2
        echo -n "."
      done
      ;;
  esac
}

# 1. CONTROLLO E AVVIO MINIO
echo -e "\n${YELLOW}1. VERIFICA MINIO${NC}"
if check_service "ricette-minio"; then
  echo -e "   ${GREEN}✅ MinIO già in esecuzione${NC}"
else
  start_service "ricette-minio"
  
  # Configurazione MinIO
  echo -e "${YELLOW}   🔧 Configurazione bucket...${NC}"
  docker exec ricette-minio /bin/sh -c "
    mc alias set local http://localhost:9000 minioadmin minioadmin >/dev/null 2>&1 || true
    mc mb local/ricette-images --ignore-existing >/dev/null 2>&1 || true
    mc anonymous set download local/ricette-images >/dev/null 2>&1 || true
  "
fi

# 2. CONTROLLO E AVVIO POSTGRESQL
echo -e "\n${YELLOW}2. VERIFICA POSTGRESQL${NC}"
if check_service "ricette-db"; then
  echo -e "   ${GREEN}✅ PostgreSQL già in esecuzione${NC}"
else
  start_service "ricette-db"
fi

# 3. VERIFICA MIGRAZIONI DATABASE
echo -e "\n${YELLOW}3. VERIFICA DATABASE${NC}"
if docker exec ricette-db psql -U postgres -d ricette_prod -c "\dt" 2>/dev/null | grep -q "public.*recipe"; then
  echo -e "   ${GREEN}✅ Tabelle database presenti${NC}"
else
  echo -e "   ${YELLOW}⚠️  Database vuoto, applico migrazioni...${NC}"
  npx prisma migrate deploy
fi

# 4. AVVIO BACKEND
echo -e "\n${YELLOW}4. AVVIO BACKEND${NC}"
echo -e "${GREEN}   🌐 Server: http://localhost:5000${NC}"
echo -e "${GREEN}   📦 MinIO: http://localhost:9001 (minioadmin/minioadmin)${NC}"
echo -e "${GREEN}   🗄️  Database: localhost:5432/ricette_prod${NC}"
echo -e "\n${YELLOW}   📝 Per fermare: ${RED}Ctrl+C${NC}"
echo -e "${YELLOW}   📋 Logs backend: ${NC}tail -f logs/*.log"
echo "======================================"

# Avvia nodemon
nodemon --exec "npx ts-node" src/server.ts