import express from 'express';
import { authenticateToken } from '../middleware/auth';
import {
  getRecipes,
  getRecipeById,
  createRecipe,
  updateRecipe,
  deleteRecipe,
  getUserRecipes,
  // LIKE FUNCTIONS
  getRecipeLikesCount,
  checkRecipeLiked,
  addLikeToRecipe,
  removeLikeFromRecipe,
  // UPLOAD IMAGE FUNCTION
  uploadRecipeImage,
  // NEW: COMMENT FUNCTIONS
  getRecipeComments,
  createComment,
  updateComment,
  deleteComment
} from '../controllers/recipe.controller';

// @ts-ignore - Ignora errore tipo multer
import multer from 'multer';

// ✅ MODIFICA: Usa memoryStorage invece di diskStorage per Vercel
const upload = multer({ 
  storage: multer.memoryStorage(), // ⬅️ MODIFICA CRUCIALE
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
  },
  fileFilter: (req: express.Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Solo immagini sono permesse'));
    }
  }
});

const router = express.Router();

// ==================== PUBLIC ROUTES ====================
router.get('/', getRecipes);
router.get('/:id', getRecipeById);
router.get('/:id/likes', getRecipeLikesCount); // Conteggio totale likes (pubblico)
router.get('/:id/comments', getRecipeComments); // Lista commenti (pubblico)

// ==================== PROTECTED ROUTES ====================
// CRUD Ricette
router.post('/', authenticateToken, upload.single('image'), createRecipe);
router.put('/:id', authenticateToken, upload.single('image'), updateRecipe);
router.delete('/:id', authenticateToken, deleteRecipe);
router.get('/user/:userId', authenticateToken, getUserRecipes);

// Upload immagine separato (per quando crei ricetta prima, immagine dopo)
router.post('/:id/upload-image', authenticateToken, upload.single('image'), uploadRecipeImage);

// Likes
router.get('/:id/liked', authenticateToken, checkRecipeLiked); // Verifica se utente ha messo like
router.post('/:id/like', authenticateToken, addLikeToRecipe); // Aggiungi like
router.delete('/:id/like', authenticateToken, removeLikeFromRecipe); // Rimuovi like

// Commenti
router.post('/:id/comments', authenticateToken, createComment); // Crea commento

export default router;