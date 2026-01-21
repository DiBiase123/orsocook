import { format } from 'winston';

// Formato per console (sviluppo) - colorato e leggibile
export const consoleFormat = format.combine(
  format.timestamp({ format: 'HH:mm:ss' }),
  format.colorize(),
  format.printf(({ timestamp, level, message, context = 'APP', ...meta }) => {
    const metaStr = meta.data ? ` ${JSON.stringify(meta.data)}` : '';
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
export const apiFormat = format.printf(({ message, ...meta }) => {
  const { method, endpoint, statusCode, userId, durationMs } = meta;
  return `${meta.timestamp} [API] ${method} ${endpoint} ${statusCode || ''} ${
    userId ? `User:${userId}` : ''
  } ${durationMs ? `${durationMs}ms` : ''}`;
});