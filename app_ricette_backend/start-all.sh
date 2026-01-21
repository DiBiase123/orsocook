#!/bin/bash
echo "🚀 AVVIO DEFINITIVO ORSOCOOK"

# 1. Avvia tutto con Docker Compose
docker-compose up -d

# 2. Attendi che i servizi siano pronti
echo "⏳ Attendo che i servizi siano pronti..."
sleep 10

# 3. Configura MinIO
echo "🔧 Configurazione MinIO..."
docker exec ricette-minio /bin/sh -c "
mc alias set local http://localhost:9000 minioadmin minioadmin
mc mb local/ricette-images --ignore-existing
mc anonymous set download local/ricette-images
"

# 4. Migrazioni database
echo "🗄️  Migrazioni database..."
npx prisma migrate deploy

# 5. Avvia backend
echo "⚡ Avvio backend..."
echo ""
echo "✅ SERVIZI:"
echo "   🌐 Backend:    http://localhost:5000"
echo "   📦 MinIO:      http://localhost:9001 (minioadmin/minioadmin)"
echo "   🗄️  Database:   localhost:5432/ricette_prod"
echo "   📱 App:        Lancia Flutter normalmente"
echo ""
echo "🛑 Per fermare: docker-compose down"
echo ""

npm run dev
