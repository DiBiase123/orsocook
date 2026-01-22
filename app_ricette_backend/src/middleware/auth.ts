import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

// Estendi l'interfaccia Request di Express
declare module 'express' {
  interface Request {
    user?: {
      id: string;
      email: string;
      role: string;
    };
    file?: any;
    files?: any[];
  }
}

// Definisci e esporta l'interfaccia COMPLETA
export interface AuthRequest extends Request {
  user: {
    id: string;
    email: string;
    role: string;
  };
  file?: any;
  files?: any[];
  body: any;
  params: any;
  query: any;
  headers: any; // <-- AGGIUNTA QUESTA
}

export const authenticateToken = (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): void => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    res.status(401).json({
      success: false,
      message: 'Token di autenticazione mancante'
    });
    return;
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    
    // ✅ NORMALIZZA I CAMPI: assicurati che ci sia sempre 'id' e 'userId'
    if (decoded && typeof decoded === 'object') {
      const userObj = decoded as any;
      req.user = {
        ...userObj,
        id: userObj.userId || userObj.userID || userObj.id,
        userId: userObj.userId || userObj.userID || userObj.id,
        email: userObj.email || '',
        role: userObj.role || 'user'
      };
    } else {
      req.user = {
        id: '',
        email: '',
        role: 'user'
      };
    }
    
    next();
  } catch (error) {
    console.error('JWT verification error:', error);
    res.status(403).json({
      success: false,
      message: 'Token non valido o scaduto'
    });
  }
};