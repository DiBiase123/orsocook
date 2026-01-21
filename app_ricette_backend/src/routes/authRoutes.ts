import express from 'express';
import multer from 'multer';
import fs from 'fs';
import path from 'path';
import { 
  register,
  login, 
  refresh, 
  logout,
  getCurrentUser,
  getUserProfile,
  updateAvatar,
  verifyEmail,
  forgotPassword,
  resetPassword,
  resendVerificationEmail
} from '../controllers/auth.controller';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

// ==================== CONFIGURAZIONE MULTER AVATAR ====================
const avatarStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = 'uploads/avatars/';
    // Crea directory se non esiste
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'avatar-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const avatarUpload = multer({ 
  storage: avatarStorage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB per avatar (meno delle ricette)
  },
  fileFilter: (req, file, cb) => {
    console.log('🔍 [MULTER FILTER] Checking file:', file.originalname, file.mimetype);
    // Accetta solo immagini
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(null, false); // NON lanciare errore!
    }
  }
});

// ==================== PUBLIC ROUTES (non richiedono autenticazione) ====================

// Registrazione tradizionale (per compatibilità)
router.post('/register', register);

// E SOTTO AGGIUNGI questa (per compatibilità frontend):
router.post('/register-with-verification', register);

// Login
router.post('/login', login);

// Refresh token
router.post('/refresh', refresh);

// Logout
router.post('/logout', logout);

// Verifica email (click sul link nell'email)
router.get('/verify-email/:token', verifyEmail);

// Richiesta reset password
router.post('/forgot-password', forgotPassword);

// Reset password con token
router.post('/reset-password/:token', resetPassword);

// Rinvia email di verifica
router.post('/resend-verification', resendVerificationEmail);

// ==================== PROTECTED ROUTES (richiedono autenticazione) ====================

// Get current user
router.get('/me', authenticateToken, getCurrentUser);

// Get user profile
router.get('/profile/:userId', authenticateToken, getUserProfile);

// Avatar upload - PROTECTED CON DEBUG
router.put(
  '/avatar', 
  authenticateToken,
  
  // MIDDLEWARE DEBUG 1: Prima di Multer
  (req: any, res: any, next: any) => {
    console.log('🔍 [MULTER DEBUG 1] Avatar upload request received');
    console.log('🔍 [MULTER DEBUG 1] Headers:', {
      'content-type': req.headers['content-type'],
      'content-length': req.headers['content-length'],
      'authorization': req.headers['authorization'] ? 'Present' : 'Missing'
    });
    console.log('🔍 [MULTER DEBUG 1] Method:', req.method);
    console.log('🔍 [MULTER DEBUG 1] URL:', req.url);
    next();
  },
  
  avatarUpload.single('avatar'),
  
  // MIDDLEWARE DEBUG 2: Dopo Multer
  (req: any, res: any, next: any) => {
    console.log('🔍 [MULTER DEBUG 2] After Multer processing');
    console.log('🔍 [MULTER DEBUG 2] req.file:', req.file ? {
      fieldname: req.file.fieldname,
      originalname: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size,
      path: req.file.path,
      buffer: req.file.buffer ? `Buffer ${req.file.buffer.length} bytes` : 'No buffer'
    } : 'NO FILE - Multer did not process file');
    console.log('🔍 [MULTER DEBUG 2] req.body:', req.body);
    
    // Se Multer non ha processato il file, passa errore
    if (!req.file) {
      console.log('❌ [MULTER DEBUG 2] Multer did not process any file');
      console.log('❌ [MULTER DEBUG 2] Possible reasons:');
      console.log('❌ [MULTER DEBUG 2] 1. Field name is not "avatar"');
      console.log('❌ [MULTER DEBUG 2] 2. File too large (>5MB)');
      console.log('❌ [MULTER DEBUG 2] 3. Not an image file');
      console.log('❌ [MULTER DEBUG 2] 4. Multipart form-data issue');
    }
    
    next();
  },
  
  updateAvatar
);

export default router;  // 👈 QUESTA È LA RIGA CHE MANCAVA