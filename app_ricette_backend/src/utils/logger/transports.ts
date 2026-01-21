import { transports } from 'winston';
import DailyRotateFile from 'winston-daily-rotate-file';
import path from 'path';
import fs from 'fs';
import { consoleFormat, fileFormat } from './formats';

// Directory per i log - CON FALLBACK SICURO E TYPE-SAFE
const getLogsDir = (): string => {
  const possibleDirs = [
    process.env.LOGS_DIR,
    path.join(process.cwd(), 'logs'),
    path.join(__dirname, '../../../logs'),
    '/tmp/orso-cook-logs',
  ];

  for (const dir of possibleDirs) {
    if (!dir) continue;
    
    try {
      // Crea directory se non esiste
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true, mode: 0o755 });
      }
      
      // Testa se è scrivibile
      const testFile = path.join(dir, '.write-test');
      fs.writeFileSync(testFile, 'test');
      fs.unlinkSync(testFile);
      
      console.log(`📁 Logs directory: ${dir}`);
      return dir;
    } catch (error: unknown) {
      // Gestione errori type-safe
      const errorMessage = error instanceof Error 
        ? error.message 
        : 'Unknown error';
      
      console.debug(`   Directory ${dir} not writable: ${errorMessage}`);
      continue;
    }
  }
  
  // Ultimo fallback: directory corrente
  console.warn('⚠️  No writable logs directory found, using current directory');
  return process.cwd();
};

const LOGS_DIR = getLogsDir();

// Transport per console
export const consoleTransport = new transports.Console({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  format: consoleFormat,
  silent: process.env.NODE_ENV === 'test',
});

// Definizione tipo per le opzioni
interface TransportOptions {
  level: string;
  filename: string;
  datePattern: string;
  maxSize: string;
  maxFiles: string;
  zippedArchive?: boolean;
}

// Helper per creare transport file con error handling TYPE-SAFE
const createFileTransport = (options: TransportOptions): DailyRotateFile | null => {
  try {
    return new DailyRotateFile({
      ...options,
      dirname: LOGS_DIR,
      format: fileFormat,
      handleExceptions: true,
      handleRejections: true,
    });
  } catch (error: unknown) {
    // Gestione errori type-safe
    const errorMessage = error instanceof Error 
      ? error.message 
      : typeof error === 'string'
        ? error
        : 'Unknown error';
    
    const errorStack = error instanceof Error ? error.stack : undefined;
    
    console.error(`❌ Failed to create file transport: ${errorMessage}`);
    if (errorStack) {
      console.error(`   Stack: ${errorStack.split('\n')[0]}`);
    }
    console.error(`   Logs dir: ${LOGS_DIR}`);
    
    return null;
  }
};

// Crea i transport con error handling
export const errorFileTransport = createFileTransport({
  level: 'error',
  filename: 'error-%DATE%.log',
  datePattern: 'YYYY-MM-DD',
  maxSize: '20m',
  maxFiles: '30d',
  zippedArchive: true,
});

export const combinedFileTransport = createFileTransport({
  level: 'info',
  filename: 'combined-%DATE%.log',
  datePattern: 'YYYY-MM-DD',
  maxSize: '20m',
  maxFiles: '14d',
  zippedArchive: false,
});

export const apiFileTransport = createFileTransport({
  level: 'info',
  filename: 'api-%DATE%.log',
  datePattern: 'YYYY-MM-DD',
  maxSize: '10m',
  maxFiles: '7d',
});

// Transport array filtrato (rimuove i null) con type assertion
export const getFileTransports = (): DailyRotateFile[] => {
  const transports = [errorFileTransport, combinedFileTransport, apiFileTransport];
  return transports.filter((t): t is DailyRotateFile => t !== null);
};