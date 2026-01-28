// Logger semplice per backend
export type LogContext = 
  | 'APP' 
  | 'API' 
  | 'DB' 
  | 'AUTH' 
  | 'RECIPE' 
  | 'FAVORITE' 
  | 'USER'
  | string;

export interface LogMeta {
  context?: LogContext;
  userId?: string;
  requestId?: string;
  durationMs?: number;
  data?: any;
  [key: string]: any;
}

// Logger principale
export class Logger {
  // Metodi principali
  static debug(message: string, meta?: LogMeta): void {
    if (process.env.NODE_ENV === 'development') {
      const context = meta?.context || 'APP';
      console.log(`🔧 [${context}] ${message}`, this._cleanMeta(meta));
    }
  }

  static info(message: string, meta?: LogMeta): void {
    const context = meta?.context || 'APP';
    // Solo in sviluppo
    if (process.env.NODE_ENV === 'development') {
      console.log(`📗 [${context}] ${message}`, this._cleanMeta(meta));
    }
  }

  static warn(message: string, meta?: LogMeta): void {
    const context = meta?.context || 'APP';
    console.warn(`📒 [${context}] ${message}`, this._cleanMeta(meta));
  }

  static error(message: string, error?: any, meta?: LogMeta): void {
    const context = meta?.context || 'APP';
    console.error(`📕 [${context}] ${message}`, error || '', this._cleanMeta(meta));
  }

  // Metodi specializzati - SOLO ERRORI (4xx, 5xx)
  static api(method: string, endpoint: string, statusCode?: number, userId?: string, durationMs?: number): void {
    // Log solo per errori (4xx, 5xx)
    if (statusCode && statusCode >= 400) {
      const message = `${method} ${endpoint}`;
      console.log(`📡 [API] ${message}`, {
        statusCode,
        userId,
        durationMs: durationMs ? `${durationMs}ms` : undefined
      });
    }
  }

  static db(operation: string, table?: string, data?: any): void {
    // Log DB solo se esplicitamente abilitato
    if (process.env.DEBUG_DB === 'true') {
      console.log(`🗄️ [DB] ${operation}`, { table, data });
    }
  }

  static auth(action: string, userId?: string, data?: any): void {
    // Log auth solo in sviluppo
    if (process.env.NODE_ENV === 'development') {
      console.log(`🔐 [AUTH] ${action}`, { userId, data });
    }
  }

  // Crea un logger con contesto predefinito
  static create(context: LogContext) {
    return {
      debug: (message: string, meta?: Omit<LogMeta, 'context'>) => 
        Logger.debug(message, { ...meta, context }),
      
      info: (message: string, meta?: Omit<LogMeta, 'context'>) => 
        Logger.info(message, { ...meta, context }),
      
      warn: (message: string, meta?: Omit<LogMeta, 'context'>) => 
        Logger.warn(message, { ...meta, context }),
      
      error: (message: string, error?: any, meta?: Omit<LogMeta, 'context'>) => 
        Logger.error(message, error, { ...meta, context }),
    };
  }

  // Helper per pulire meta
  private static _cleanMeta(meta?: LogMeta): any {
    if (!meta) return {};
    const { context, ...rest } = meta;
    return rest;
  }
}

// Esporta il logger principale
export default Logger;

// Logger preconfigurati
export const ApiLogger = Logger.create('API');
export const DbLogger = Logger.create('DB');
export const AuthLogger = Logger.create('AUTH');
export const RecipeLogger = Logger.create('RECIPE');
export const FavoriteLogger = Logger.create('FAVORITE');
export const UserLogger = Logger.create('USER');