import app from './app';

const PORT = parseInt(process.env.PORT || '5000', 10);

async function initializeDatabase() {
  try {
    console.log('🔧 Verifica connessione database...');
    
    const { PrismaClient } = require('@prisma/client');
    const prisma = new PrismaClient();
    
    // Test connessione
    await prisma.$queryRaw`SELECT 1`;
    console.log('✅ Database connesso');
    
    // Verifica se le tabelle esistono
    try {
      await prisma.recipe.count();
      console.log('✅ Tabelle presenti');
    } catch (error) {
      console.log('⚠️  Tabelle mancanti, creazione...');
      const { execSync } = require('child_process');
      execSync('npx prisma db push', { stdio: 'inherit' });
      console.log('✅ Tabelle create');
    }
    
    await prisma.$disconnect();
  } catch (error) {
    console.error('❌ Errore database:', error);
    throw error;
  }
}

async function startServer() {
  try {
    console.log('🔧 Inizializzazione...');
    
    // Inizializza database
    await initializeDatabase();
    
    console.log('🚀 Avvio server...');
    const server = app.listen(PORT, '0.0.0.0', () => {
      console.log(`✅ Server running on port ${PORT}`);
      console.log(`📁 Health check: http://localhost:${PORT}/health`);
      console.log(`☁️  Cloudinary configurato per le immagini`);
      console.log(`🛠️  API Base: http://localhost:${PORT}/api`);
    });
    
    return server;
  } catch (error) {
    console.error('❌ Errore inizializzazione:', error);
    process.exit(1);
  }
}

startServer();