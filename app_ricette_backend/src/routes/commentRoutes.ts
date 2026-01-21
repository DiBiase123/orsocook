import express from 'express';
import { authenticateToken } from '../middleware/auth';
import {
  updateComment,
  deleteComment
} from '../controllers/recipe.controller';

const router = express.Router();

// ==================== COMMENT ROUTES ====================
router.put('/:commentId', authenticateToken, updateComment);
router.delete('/:commentId', authenticateToken, deleteComment);

export default router;
