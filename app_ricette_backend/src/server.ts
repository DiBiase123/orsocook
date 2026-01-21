// src/server.ts
import app from './app';
import { initializeMinIO } from './utils/minio'; // <-- AGGIUNGI QUESTA RIGA

const PORT = parseInt(process.env.PORT || '5000', 10);

// Funzione per inizializzare tutto
async function startServer() {
  try {
    console.log('🔧 Inizializzazione MinIO...');
    await initializeMinIO(); // <-- AGGIUNGI QUESTA CHIAMATA
    console.log('✅ MinIO pronto');
    
    const server = app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📁 Health check: http://localhost:${PORT}/health`);
      console.log(`📦 MinIO Console: http://localhost:9001`);
      console.log(`🪣 Bucket: ricette-images`);
    });
    
    return server;
  } catch (error) {
    console.error('❌ Errore inizializzazione:', error);
    process.exit(1);
  }
}

// Avvia il server
startServer();