import fetch from 'node-fetch';
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

// Import routes
import recipeRoutes from './routes/recipeRoutes';
import categoryRoutes from './routes/categoryRoutes';
import authRoutes from './routes/authRoutes';
import favoriteRoutes from './routes/favoriteRoutes'; // <-- NUOVA IMPORT
import commentRoutes from './routes/commentRoutes';


// Carica variabili ambiente
dotenv.config();

const app = express();

// Middleware
app.use(cors({
  origin: true,  // Permetti tutti in sviluppo
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static('uploads'));

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'orso-cook-api',
    version: '1.0.0'
  });
});

// API Routes
app.use('/api/recipes', recipeRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/favorites', favoriteRoutes);
app.use('/api/comments', commentRoutes);


// Proxy per immagini MinIO (evita problemi CORS) - DEVE STARE PRIMA DEL 404 HANDLER
app.get('/api/images/:bucket/:path(*)', async (req, res) => {
  try {
    const { bucket, path } = req.params;
    const minioUrl = `http://localhost:9000/${bucket}/${path}`;
    
    console.log(`📤 Proxy request: ${minioUrl}`);
    
    const fetchResponse = await fetch(minioUrl);
    
    if (!fetchResponse.ok) {
      console.log(`❌ MinIO response: ${fetchResponse.status} ${fetchResponse.statusText}`);
      return res.status(fetchResponse.status).send('Image not found');
    }
    
    // Copia headers
    const contentType = fetchResponse.headers.get('content-type');
    if (contentType) {
      res.set('Content-Type', contentType);
    }
    
    // Stream della risposta
    const buffer = await fetchResponse.arrayBuffer();
    res.send(Buffer.from(buffer));
    
    console.log(`✅ Proxy success for: ${minioUrl}`);
    
  } catch (error) {
    console.error('❌ Proxy image error:', error);
    res.status(500).send('Error fetching image');
  }
});

// 404 handler (DEVE STARE DOPO TUTTE LE ROUTE)
app.use((req, res) => {
  console.log(`❌ 404: ${req.method} ${req.originalUrl}`);
  res.status(404).json({
    success: false,
    error: 'Route not found',
    path: req.originalUrl,
    method: req.method
  });
});

// Error handler
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('❌ Errore server:', err);
  
  res.status(err.status || 500).json({
    success: false,
    error: process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message,
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
  });
});

export default app;