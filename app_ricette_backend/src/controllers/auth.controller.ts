import { Request, Response } from 'express';
const bcrypt = require('bcrypt');
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';
import { uploadImageToCloudinary } from '../services/cloudinary.service';
import { emailService } from '../services/email.service';
import crypto from 'crypto';

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
const REFRESH_SECRET = process.env.REFRESH_SECRET || 'your-refresh-secret';

// Configurazioni sicurezza
const MAX_LOGIN_ATTEMPTS = parseInt(process.env.MAX_LOGIN_ATTEMPTS || '5');
const ACCOUNT_LOCK_TIME = parseInt(process.env.ACCOUNT_LOCK_TIME_MINUTES || '15') * 60 * 1000;
const EMAIL_TOKEN_EXPIRY = parseInt(process.env.EMAIL_TOKEN_EXPIRY_HOURS || '24') * 60 * 60 * 1000;
const RESET_TOKEN_EXPIRY = parseInt(process.env.RESET_TOKEN_EXPIRY_MINUTES || '60') * 60 * 1000;

// Generate tokens utility
const generateTokens = (user: any) => ({
  accessToken: jwt.sign(
    { 
      id: user.id, 
      username: user.username, 
      email: user.email,
      isVerified: user.isVerified 
    },
    JWT_SECRET,
    { expiresIn: '15m' }
  ),
  refreshToken: jwt.sign(
    { id: user.id },
    REFRESH_SECRET,
    { expiresIn: '7d' }
  )
});

// Sanitize user response
const sanitizeUser = (user: any) => {
  const { passwordHash, emailToken, emailTokenExpiry, resetToken, resetTokenExpiry, loginAttempts, lockedUntil, ...safeUser } = user;
  return safeUser;
};

// Check if account is locked
const isAccountLocked = (user: any): boolean => {
  if (!user.lockedUntil) return false;
  return new Date(user.lockedUntil) > new Date();
};

// Reset login attempts on successful login
const resetLoginAttempts = async (userId: string) => {
  await prisma.user.update({
    where: { id: userId },
    data: { 
      loginAttempts: 0,
      lockedUntil: null,
      lastLogin: new Date()
    }
  });
};

// Increment login attempts and lock if necessary
const incrementLoginAttempts = async (user: any) => {
  const newAttempts = (user.loginAttempts || 0) + 1;
  const lockUntil = newAttempts >= MAX_LOGIN_ATTEMPTS 
    ? new Date(Date.now() + ACCOUNT_LOCK_TIME)
    : null;

  await prisma.user.update({
    where: { id: user.id },
    data: { 
      loginAttempts: newAttempts,
      lockedUntil: lockUntil
    }
  });

  return { locked: lockUntil !== null, lockUntil };
};

// ==================== REGISTRAZIONE UNICA CON VERIFICA EMAIL ====================

export const register = async (req: Request, res: Response): Promise<void> => {
  // Chiama direttamente la nuova funzione con verifica email
  return registerWithVerification(req, res);
};

// ==================== NUOVA REGISTRAZIONE CON VERIFICA EMAIL ====================

export const registerWithVerification = async (req: Request, res: Response): Promise<void> => {
  try {
    const { username, email, password } = req.body;
    
    if (!username || !email || !password) {
      res.status(400).json({ success: false, message: 'Campi obbligatori mancanti' });
      return;
    }

    // Validazione email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      res.status(400).json({ success: false, message: 'Formato email non valido' });
      return;
    }

    // Validazione password
    if (password.length < 8) {
      res.status(400).json({ success: false, message: 'Password deve essere di almeno 8 caratteri' });
      return;
    }

    // Verifica se utente esiste già
    const existingUser = await prisma.user.findFirst({
      where: { 
        OR: [{ email }, { username }] 
      }
    });

    if (existingUser) {
      const message = existingUser.email === email 
        ? 'Email già registrata' 
        : 'Username già in uso';
      res.status(400).json({ success: false, message });
      return;
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);
    
    // Genera token di verifica unico
    const emailToken = crypto.randomBytes(32).toString('hex');
    const emailTokenExpiry = new Date(Date.now() + EMAIL_TOKEN_EXPIRY);

    // Crea utente NON verificato
    const user = await prisma.user.create({
      data: { 
        username, 
        email, 
        passwordHash: hashedPassword,
        emailToken,
        emailTokenExpiry,
        isVerified: false
      },
      select: { 
        id: true, 
        username: true, 
        email: true, 
        avatarUrl: true, 
        isVerified: true,
        createdAt: true 
      }
    });

    // Invia email di verifica
    const emailSent = await emailService.sendVerificationEmail(
      email, 
      emailToken, 
      username
    );

    if (!emailSent) {
      console.warn(`⚠️  Email di verifica non inviata per ${email}`);
    }

    // NON generare token JWT - l'utente deve prima verificare l'email
    res.status(201).json({
      success: true,
      message: 'Registrazione completata! Verifica la tua email per attivare l\'account.',
      data: { 
        user,
        requiresVerification: true,
        emailSent
      }
    });
  } catch (error) {
    console.error('Register with verification error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore durante la registrazione' 
    });
  }
};

// ==================== VERIFICA EMAIL ====================

export const verifyEmail = async (req: Request, res: Response): Promise<void> => {
  try {
    const { token } = req.params;

    if (!token) {
      res.status(400).json({ success: false, message: 'Token mancante' });
      return;
    }

    // Trova utente con token valido e non scaduto
    const user = await prisma.user.findFirst({
      where: {
        emailToken: token,
        emailTokenExpiry: {
          gt: new Date() // Token non scaduto
        }
      }
    });

    if (!user) {
      res.status(400).json({ 
        success: false, 
        message: 'Token di verifica non valido o scaduto' 
      });
      return;
    }

    // Verifica l'account
    const verifiedUser = await prisma.user.update({
      where: { id: user.id },
      data: { 
        isVerified: true,
        emailToken: null,
        emailTokenExpiry: null
      },
      select: { 
        id: true, 
        username: true, 
        email: true, 
        avatarUrl: true, 
        isVerified: true,
        createdAt: true 
      }
    });

    // Genera token per login automatico dopo verifica
    const { accessToken, refreshToken } = generateTokens(verifiedUser);

    res.json({
      success: true,
      message: '🎉 Account verificato con successo! Ora puoi accedere.',
      data: { 
        user: verifiedUser,
        token: accessToken,
        refreshToken
      }
    });
  } catch (error) {
    console.error('Verify email error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore durante la verifica dell\'email' 
    });
  }
};

// ==================== LOGIN CON SICUREZZA ====================

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      res.status(400).json({ success: false, message: 'Email e password obbligatorie' });
      return;
    }

    const user = await prisma.user.findUnique({ 
      where: { email },
      include: { sessions: true }
    });

    if (!user) {
      res.status(401).json({ success: false, message: 'Credenziali non valide' });
      return;
    }

    // Controlla se l'account è bloccato
    if (isAccountLocked(user)) {
      const lockTime = new Date(user.lockedUntil!).getTime() - Date.now();
      const minutesLeft = Math.ceil(lockTime / (60 * 1000));
      
      res.status(423).json({ 
        success: false, 
        message: `Account temporaneamente bloccato. Riprova tra ${minutesLeft} minuti.`,
        locked: true,
        lockTime: minutesLeft
      });
      return;
    }

    // Controlla se l'email è verificata
    if (!user.isVerified) {
      res.status(403).json({ 
        success: false, 
        message: 'Devi verificare la tua email prima di accedere.',
        requiresVerification: true,
        email: user.email
      });
      return;
    }

    // Verifica password
    const passwordValid = await bcrypt.compare(password, user.passwordHash);
    
    if (!passwordValid) {
      // Incrementa tentativi falliti
      const { locked, lockUntil } = await incrementLoginAttempts(user);
      
      if (locked) {
        const lockTime = new Date(lockUntil!).getTime() - Date.now();
        const minutesLeft = Math.ceil(lockTime / (60 * 1000));
        
        res.status(423).json({ 
          success: false, 
          message: `Troppi tentativi falliti. Account bloccato per ${minutesLeft} minuti.`,
          locked: true,
          lockTime: minutesLeft
        });
      } else {
        const attemptsLeft = MAX_LOGIN_ATTEMPTS - (user.loginAttempts || 0) - 1;
        res.status(401).json({ 
          success: false, 
          message: `Credenziali non valide. Tentativi rimasti: ${attemptsLeft}`,
          attemptsLeft
        });
      }
      return;
    }

    // Login riuscito - reset tentativi
    await resetLoginAttempts(user.id);

    const { accessToken, refreshToken } = generateTokens(user);
    const userData = sanitizeUser(user);

    // Cerca se esiste già una sessione per questo utente
    const existingSession = await prisma.session.findFirst({
      where: { userId: user.id }
    });

    if (existingSession) {
      // Aggiorna sessione esistente
      await prisma.session.update({
        where: { id: existingSession.id },
        data: { 
          refreshToken,
          expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 giorni
        }
      });
    } else {
      // Crea nuova sessione
      await prisma.session.create({
        data: {
          userId: user.id,
          refreshToken,
          expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
        }
      });
    }

    res.json({
      success: true,
      message: 'Login effettuato',
      data: { user: userData, token: accessToken, refreshToken }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, message: 'Errore durante il login' });
  }
};

// ==================== FORGOT PASSWORD ====================

export const forgotPassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email } = req.body;

    if (!email) {
      res.status(400).json({ success: false, message: 'Email obbligatoria' });
      return;
    }

    const user = await prisma.user.findUnique({ where: { email } });

    if (!user) {
      // Per sicurezza, non rivelare se l'email esiste
      res.json({
        success: true,
        message: 'Se l\'email è registrata, riceverai istruzioni per il reset'
      });
      return;
    }

    // Genera token di reset
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenExpiry = new Date(Date.now() + RESET_TOKEN_EXPIRY);

    // Salva token nel database
    await prisma.user.update({
      where: { id: user.id },
      data: { resetToken, resetTokenExpiry }
    });

    // Invia email di reset
    const emailSent = await emailService.sendPasswordResetEmail(
      email,
      resetToken,
      user.username
    );

    res.json({
      success: true,
      message: 'Se l\'email è registrata, riceverai istruzioni per il reset',
      data: { emailSent }
    });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore durante la richiesta di reset password' 
    });
  }
};

// ==================== RESET PASSWORD ====================

export const resetPassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const { token } = req.params;
    const { password, confirmPassword } = req.body;

    if (!token || !password || !confirmPassword) {
      res.status(400).json({ 
        success: false, 
        message: 'Token, password e conferma password obbligatori' 
      });
      return;
    }

    if (password !== confirmPassword) {
      res.status(400).json({ 
        success: false, 
        message: 'Le password non corrispondono' 
      });
      return;
    }

    if (password.length < 8) {
      res.status(400).json({ 
        success: false, 
        message: 'Password deve essere di almeno 8 caratteri' 
      });
      return;
    }

    // Trova utente con token valido
    const user = await prisma.user.findFirst({
      where: {
        resetToken: token,
        resetTokenExpiry: {
          gt: new Date() // Token non scaduto
        }
      }
    });

    if (!user) {
      res.status(400).json({ 
        success: false, 
        message: 'Token di reset non valido o scaduto' 
      });
      return;
    }

    // Hash nuova password
    const hashedPassword = await bcrypt.hash(password, 12);

    // Aggiorna password e pulisci token
    await prisma.user.update({
      where: { id: user.id },
      data: { 
        passwordHash: hashedPassword,
        resetToken: null,
        resetTokenExpiry: null,
        loginAttempts: 0, // Reset tentativi falliti
        lockedUntil: null // Sblocca account se era bloccato
      }
    });

    res.json({
      success: true,
      message: '🎉 Password reimpostata con successo! Ora puoi accedere con la nuova password.'
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore durante il reset della password' 
    });
  }
};

// ==================== RESEND VERIFICATION EMAIL ====================

export const resendVerificationEmail = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email } = req.body;

    if (!email) {
      res.status(400).json({ success: false, message: 'Email obbligatoria' });
      return;
    }

    const user = await prisma.user.findUnique({ 
      where: { email },
      select: { id: true, username: true, email: true, isVerified: true }
    });

    if (!user) {
      // Per sicurezza, non rivelare se l'email esiste
      res.json({
        success: true,
        message: 'Se l\'email è registrata, riceverai una nuova email di verifica'
      });
      return;
    }

    if (user.isVerified) {
      res.status(400).json({ 
        success: false, 
        message: 'Account già verificato' 
      });
      return;
    }

    // Genera nuovo token
    const emailToken = crypto.randomBytes(32).toString('hex');
    const emailTokenExpiry = new Date(Date.now() + EMAIL_TOKEN_EXPIRY);

    // Aggiorna token nel database
    await prisma.user.update({
      where: { id: user.id },
      data: { emailToken, emailTokenExpiry }
    });

    // Invia email
    const emailSent = await emailService.sendVerificationEmail(
      email,
      emailToken,
      user.username
    );

    res.json({
      success: true,
      message: 'Nuova email di verifica inviata',
      data: { emailSent }
    });
  } catch (error) {
    console.error('Resend verification email error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore durante l\'invio della nuova email di verifica' 
    });
  }
};

// ==================== FUNZIONI ESISTENTI (mantenute) ====================

export const refresh = async (req: Request, res: Response): Promise<void> => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      res.status(400).json({ success: false, message: 'Refresh token mancante' });
      return;
    }

    const decoded = jwt.verify(refreshToken, REFRESH_SECRET) as { id: string };
    const user = await prisma.user.findUnique({
      where: { id: decoded.id },
      select: { id: true, username: true, email: true, isVerified: true }
    });

    if (!user) {
      res.status(401).json({ success: false, message: 'Utente non trovato' });
      return;
    }

    const newToken = jwt.sign(
      { id: user.id, username: user.username, email: user.email, isVerified: user.isVerified },
      JWT_SECRET,
      { expiresIn: '15m' }
    );

    res.json({ success: true, message: 'Token aggiornato', data: { token: newToken } });
  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(401).json({ success: false, message: 'Refresh token non valido' });
  }
};

export const getCurrentUser = async (req: any, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Utente non autenticato' });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: { 
        id: true, 
        username: true, 
        email: true, 
        avatarUrl: true, 
        isVerified: true,
        createdAt: true, 
        updatedAt: true 
      }
    });

    res.json({ success: true, data: user });
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({ success: false, message: 'Errore interno del server' });
  }
};

export const getUserProfile = async (req: any, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Utente non autenticato' });
      return;
    }

    const userId = req.params.userId;
    if (req.user.id !== userId) {
      res.status(403).json({ success: false, message: 'Non autorizzato' });
      return;
    }

    const [user, recipesCount, favoritesCount, recentRecipes, recentFavorites, recipesViewsResult] = await Promise.all([
      prisma.user.findUnique({
        where: { id: userId },
        select: { id: true, username: true, email: true, avatarUrl: true, createdAt: true, updatedAt: true, isVerified: true }
      }),
      prisma.recipe.count({ where: { authorId: userId } }),
      prisma.favorite.count({ where: { userId } }),
      prisma.recipe.findMany({
        where: { authorId: userId },
        take: 5,
        orderBy: { createdAt: 'desc' },
        include: {
          category: true,
          tags: { include: { tag: true } },
          favorites: { where: { userId }, select: { id: true } },
          _count: { select: { favorites: true, likes: true } }
        }
      }),
      prisma.favorite.findMany({
        where: { userId },
        take: 5,
        orderBy: { createdAt: 'desc' },
        include: {
          recipe: {
            include: {
              category: true,
              tags: { include: { tag: true } },
              author: { select: { id: true, username: true, email: true, avatarUrl: true, isVerified: true } },
              _count: { select: { favorites: true, likes: true } }
            }
          }
        }
      }),
      prisma.recipe.aggregate({ where: { authorId: userId }, _sum: { views: true } })
    ]);

    if (!user) {
      res.status(404).json({ success: false, message: 'Utente non trovato' });
      return;
    }

    const totalViews = recipesViewsResult._sum.views || 0;

    res.json({
      success: true,
      data: {
        user,
        stats: {
          recipesCount,
          favoritesCount,
          totalViews,
          averageViewsPerRecipe: recipesCount > 0 ? Math.round(totalViews / recipesCount) : 0
        },
        recentRecipes: recentRecipes.map(recipe => ({
          id: recipe.id,
          title: recipe.title,
          description: recipe.description,
          imageUrl: recipe.imageUrl,
          prepTime: recipe.prepTime,
          cookTime: recipe.cookTime,
          difficulty: recipe.difficulty,
          views: recipe.views,
          createdAt: recipe.createdAt,
          category: recipe.category,
          tags: recipe.tags.map((t: any) => t.tag),
          favoriteCount: recipe._count.favorites,
          likeCount: recipe._count.likes,
          isFavorite: recipe.favorites.length > 0
        })),
        recentFavorites: recentFavorites.map(fav => ({
          id: fav.recipe.id,
          title: fav.recipe.title,
          description: fav.recipe.description,
          imageUrl: fav.recipe.imageUrl,
          prepTime: fav.recipe.prepTime,
          cookTime: fav.recipe.cookTime,
          difficulty: fav.recipe.difficulty,
          views: fav.recipe.views,
          createdAt: fav.recipe.createdAt,
          category: fav.recipe.category,
          tags: fav.recipe.tags.map((t: any) => t.tag),
          author: fav.recipe.author,
          favoriteCount: fav.recipe._count.favorites,
          likeCount: fav.recipe._count.likes,
          isFavorite: true
        }))
      }
    });
  } catch (error) {
    console.error('Get user profile error:', error);
    res.status(500).json({ success: false, message: 'Errore nel recupero del profilo' });
  }
};

export const updateAvatar = async (req: any, res: Response): Promise<void> => {
  try {
    console.log('🔄 [updateAvatar] Starting avatar update process');
    
    if (!req.user || !req.user.id) {
      res.status(401).json({ success: false, message: 'Utente non autenticato' });
      return;
    }

    if (!req.file) {
      console.log('❌ [updateAvatar] No file provided by Multer');
      res.status(400).json({ success: false, message: 'Nessuna immagine fornita' });
      return;
    }

    console.log('📄 [updateAvatar] File details:', {
      originalname: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size,
      bufferLength: req.file.buffer?.length || 0
    });

    // Validazione
    if (!req.file.mimetype.startsWith('image/') || req.file.size > 5 * 1024 * 1024) {
      res.status(400).json({ success: false, message: 'Immagine non valida o troppo grande (max 5MB)' });
      return;
    }

    const userId = req.user.id;
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { avatarUrl: true }
    });

    // 🚨 IMPORTANTE: NOTA SULLA CANCELLAZIONE
    // Per cancellare un'immagine vecchia da Cloudinary, avremmo bisogno del public_id
    // Nota: l'immagine vecchia potrebbe essere su storage precedente
    // Per ora, saltiamo la cancellazione e gestiamo solo il nuovo upload
    
    // Se vuoi implementare la cancellazione futura, dovrai:
    // 1. Salvare il public_id di Cloudinary nel database
    // 2. Oppure estrarre public_id dall'URL (complesso)

    // 🚨 MODIFICA: Upload nuovo avatar a Cloudinary
    console.log('📤 [updateAvatar] Uploading to Cloudinary...');
    const fileBuffer = req.file.buffer;
    
    if (!fileBuffer || fileBuffer.length === 0) {
      console.error('❌ [updateAvatar] File buffer is empty');
      res.status(500).json({ 
        success: false, 
        message: 'Errore nel caricamento dell\'immagine' 
      });
      return;
    }

    // Upload a Cloudinary nella cartella 'orsocook/avatars'
    const imageUrl = await uploadImageToCloudinary(fileBuffer, 'orsocook/avatars');
    console.log('✅ [updateAvatar] Avatar uploaded to Cloudinary:', imageUrl);

    // Aggiorna URL nel database
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: { 
        avatarUrl: imageUrl,
        updatedAt: new Date() 
      },
      select: { 
        id: true, 
        username: true, 
        email: true, 
        avatarUrl: true, 
        isVerified: true, 
        createdAt: true, 
        updatedAt: true 
      }
    });

    res.json({
      success: true,
      message: '🎉 Avatar aggiornato con successo!',
      data: { user: updatedUser }
    });
  } catch (error) {
    console.error('❌ [updateAvatar] Error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore durante l\'aggiornamento dell\'avatar',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
};

export const logout = async (req: Request, res: Response): Promise<void> => {
  try {
    const { refreshToken } = req.body;
    
    if (refreshToken) {
      await prisma.session.deleteMany({
        where: { refreshToken }
      });
    }
    
    res.json({ success: true, message: 'Logout effettuato' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ success: false, message: 'Errore durante il logout' });
  }
};

// ==================== EXPORT COMPLETO ====================

export default {
  // Registrazione - UNICA VERSIONE (con verifica email)
  register,
  
  // Verifica email
  verifyEmail,
  resendVerificationEmail,
  
  // Login/logout
  login,
  logout,
  refresh,
  
  // Password
  forgotPassword,
  resetPassword,
  
  // Profilo
  getCurrentUser,
  getUserProfile,
  updateAvatar
};