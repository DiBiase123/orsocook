import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

// Definisci e esporta l'interfaccia
export interface AuthRequest extends Request {
  user?: any;
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
        userId: userObj.userId || userObj.userID || userObj.id
      };
    } else {
      req.user = decoded;
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