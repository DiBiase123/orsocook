import app from './app';

const PORT = parseInt(process.env.PORT || '5000', 10);

// Funzione per inizializzare tutto
async function startServer() {
  try {
    console.log('🔧 Server in avvio...');
    
    const server = app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📁 Health check: http://localhost:${PORT}/health`);
      console.log(`☁️  Cloudinary configurato per le immagini`);
    });
    
    return server;
  } catch (error) {
    console.error('❌ Errore inizializzazione:', error);
    process.exit(1);
  }
}

// Avvia il server
startServer();