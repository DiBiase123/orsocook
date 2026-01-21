import { format } from 'winston';

// Definizione tipo per i meta
interface LogInfo {
  timestamp?: string;
  level: string;
  message: string;
  context?: string;
  data?: any;
  method?: string;
  endpoint?: string;
  statusCode?: number;
  userId?: string;
  durationMs?: number;
  [key: string]: any;
}

// Formato per console (sviluppo) - colorato e leggibile
export const consoleFormat = format.combine(
  format.timestamp({ format: 'HH:mm:ss' }),
  format.colorize(),
  format.printf((info: LogInfo) => {
    const { timestamp, level, message, context = 'APP', data, ...meta } = info;
    const metaStr = data ? ` ${JSON.stringify(data)}` : '';
    return `${timestamp} [${level}] [${context}] ${message}${metaStr}`;
  })
);

// Formato per file (produzione) - JSON strutturato
export const fileFormat = format.combine(
  format.timestamp(),
  format.errors({ stack: true }),
  format.json()
);

// Formato per API logging
export const apiFormat = format.printf((info: LogInfo) => {
  const { timestamp, message, method, endpoint, statusCode, userId, durationMs } = info;
  return `${timestamp} [API] ${method} ${endpoint} ${statusCode || ''} ${
    userId ? `User:${userId}` : ''
  } ${durationMs ? `${durationMs}ms` : ''} - ${message}`;
});