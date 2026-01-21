import * as Minio from 'minio';
import fs from 'fs';
import path from 'path';

// Configurazione MinIO
const minioClient = new Minio.Client({
  endPoint: process.env.MINIO_ENDPOINT || 'localhost',
  port: parseInt(process.env.MINIO_PORT || '9000', 10),
  useSSL: process.env.MINIO_USE_SSL === 'true',
  accessKey: process.env.MINIO_ACCESS_KEY || 'minioadmin',
  secretKey: process.env.MINIO_SECRET_KEY || 'minioadmin',
});

const BUCKET_NAME = process.env.MINIO_BUCKET_NAME || 'ricette-images';

// Inizializza bucket CON RETRY INTELLIGENTE
export async function initializeMinIO() {
  const maxRetries = 5;
  const retryDelay = 3000; // 3 secondi
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.log(`🔧 Tentativo ${attempt}/${maxRetries} connessione a MinIO...`);
      
      // Testa se MinIO risponde
      const bucketExists = await minioClient.bucketExists(BUCKET_NAME);
      
      if (!bucketExists) {
        await minioClient.makeBucket(BUCKET_NAME, 'us-east-1');
        console.log(`✅ Bucket "${BUCKET_NAME}" creato`);
      } else {
        console.log(`✅ Bucket "${BUCKET_NAME}" già esistente`);
      }
      
      console.log('✅ MinIO connesso e pronto');
      return;
      
    } catch (error: any) {
      if (error.code === 'ECONNREFUSED') {
        console.log(`⚠️  MinIO non ancora pronto (${attempt}/${maxRetries})`);
      } else {
        console.log(`⚠️  Errore MinIO: ${error.message}`);
      }
      
      if (attempt < maxRetries) {
        console.log(`⏳ Attendo ${retryDelay/1000}s prima di riprovare...`);
        await new Promise(resolve => setTimeout(resolve, retryDelay));
      } else {
        console.log('❌ MinIO non disponibile dopo tutti i tentativi');
        console.log('💡 Verifica manualmente:');
        console.log('   1. docker ps | grep minio');
        console.log('   2. docker start ricette-minio');
        console.log('   3. Attendi 5 secondi');
        console.log('   4. Controlla: http://localhost:9001');
        // Non blocchiamo il server, solo warning
        console.log('⚠️  Il server partirà comunque, ma le immagini potrebbero non funzionare');
      }
    }
  }
}

// Upload file - VERSIONE MIGLIORATA PER AVATAR
export async function uploadToMinIO(
  file: Express.Multer.File, 
  folder: string = ''
): Promise<{ url: string; filename: string }> {
  try {
    const fileExtension = path.extname(file.originalname);
    const timestamp = Date.now();
    const random = Math.floor(Math.random() * 1000000);
    
    // Gestione speciale per avatar: usa prefisso diverso e naming più pulito
    let filename: string;
    if (folder === 'avatars') {
      filename = `avatars/avatar_${timestamp}_${random}${fileExtension}`;
    } else {
      filename = `${folder}/recipe_${timestamp}_${random}${fileExtension}`;
    }
    
    const metaData = {
      'Content-Type': file.mimetype,
    };

    await minioClient.fPutObject(BUCKET_NAME, filename, file.path, metaData);
    
    // Usa il proxy backend invece dell'URL diretto MinIO
    const port = process.env.PORT || 5000;
    const url = `http://localhost:${port}/api/images/${BUCKET_NAME}/${filename}`;
    
    console.log(`✅ File caricato su MinIO: ${filename} (tipo: ${folder === 'avatars' ? 'avatar' : 'ricetta'})`);
    
    return {
      url,
      filename
    };
  } catch (error) {
    console.error('❌ Errore upload MinIO:', error);
    throw error;
  }
}

// Delete file - VERSIONE MIGLIORATA
export async function deleteFromMinIO(filename: string): Promise<void> {
  try {
    // Controlla se il file esiste prima di eliminarlo (evita errori 404)
    try {
      await minioClient.statObject(BUCKET_NAME, filename);
    } catch (statError) {
      console.log(`⚠️  File non trovato su MinIO, skip eliminazione: ${filename}`);
      return; // Non fare nulla se il file non esiste
    }
    
    await minioClient.removeObject(BUCKET_NAME, filename);
    console.log(`✅ File cancellato da MinIO: ${filename}`);
  } catch (error: any) {
    // Non bloccare se l'eliminazione fallisce (es: file già cancellato)
    if (error.code === 'NoSuchKey') {
      console.log(`⚠️  File già cancellato: ${filename}`);
    } else {
      console.error('❌ Errore cancellazione MinIO:', error);
      throw error;
    }
  }
}

// Funzione per testare la connessione (utility)
export async function testMinIOConnection(): Promise<boolean> {
  try {
    await minioClient.bucketExists(BUCKET_NAME);
    return true;
  } catch {
    return false;
  }
}

// Nuova funzione: elimina tutti gli avatar di un utente (per cleanup)
export async function deleteUserAvatars(userId: string): Promise<void> {
  try {
    // Lista tutti gli oggetti nel bucket con prefisso avatars/
    const objectsStream = minioClient.listObjectsV2(BUCKET_NAME, 'avatars/', true);
    
    const avatarsToDelete: string[] = [];
    
    for await (const obj of objectsStream) {
      if (obj.name && obj.name.includes(`avatar_${userId}_`)) {
        avatarsToDelete.push(obj.name);
      }
    }
    
    // Elimina tutti gli avatar trovati
    if (avatarsToDelete.length > 0) {
      await minioClient.removeObjects(BUCKET_NAME, avatarsToDelete);
      console.log(`✅ ${avatarsToDelete.length} avatar eliminati per utente ${userId}`);
    }
  } catch (error) {
    console.error('❌ Errore eliminazione avatar utente:', error);
    // Non bloccare, è solo cleanup
  }
}

export default minioClient;