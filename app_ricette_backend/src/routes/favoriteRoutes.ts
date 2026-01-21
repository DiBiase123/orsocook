import express from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticateToken } from '../middleware/auth';
import Logger from '../utils/logger';  // Importa il nostro nuovo logger

const router = express.Router();
const prisma = new PrismaClient();

// ============ MIDDLEWARE ============
router.use(authenticateToken);

// ============ ENDPOINTS ============

// GET /api/favorites - Lista dei preferiti dell'utente
router.get('/', async (req: any, res) => {
  const startTime = Date.now();
  
  try {
    const userId = req.user.userId;
    
    Logger.api('GET', '/api/favorites', undefined, userId);
    Logger.db('SELECT favorites', 'Favorite', { userId });
    
    const favorites = await prisma.favorite.findMany({
      where: { userId },
      include: {
        recipe: {
          include: {
            author: {
              select: { id: true, username: true, email: true }
            },
            category: true,
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    const recipes = favorites.map(fav => ({
      ...fav.recipe,
      isFavorite: true,
      favoritedAt: fav.createdAt
    }));
    
    const duration = Date.now() - startTime;
    Logger.api('GET', '/api/favorites', 200, userId, duration);
    Logger.info(`Found ${recipes.length} favorites for user ${userId}`, { 
      context: 'FAVORITE',
      userId,
      count: recipes.length,
      durationMs: duration
    });
    
    res.json(recipes);
  } catch (error) {
    const duration = Date.now() - startTime;
    Logger.error('Errore nel recupero preferiti', error, {
      context: 'FAVORITE',
      endpoint: '/api/favorites',
      durationMs: duration
    });
    res.status(500).json({ error: 'Errore nel recupero preferiti' });
  }
});

// POST /api/favorites/:recipeId - Aggiungi ai preferiti
router.post('/:recipeId', async (req: any, res) => {
  const startTime = Date.now();
  
  try {
    const userId = req.user.userId;
    const { recipeId } = req.params;

    Logger.api('POST', `/api/favorites/${recipeId}`, undefined, userId);
    Logger.db('CREATE favorite', 'Favorite', { userId, recipeId });
    
    // Verifica che la ricetta esista
    const recipe = await prisma.recipe.findUnique({
      where: { id: recipeId }
    });

    if (!recipe) {
      Logger.warn(`Recipe not found`, {
        context: 'FAVORITE',
        userId,
        recipeId
      });
      return res.status(404).json({ error: 'Ricetta non trovata' });
    }

    // Verifica se già tra i preferiti
    const existingFavorite = await prisma.favorite.findUnique({
      where: {
        userId_recipeId: {
          userId,
          recipeId
        }
      }
    });

    if (existingFavorite) {
      Logger.warn(`Recipe already favorited`, {
        context: 'FAVORITE',
        userId,
        recipeId
      });
      return res.status(400).json({ error: 'Ricetta già nei preferiti' });
    }

    // Crea il preferito
    const favorite = await prisma.favorite.create({
      data: {
        userId,
        recipeId
      },
      include: {
        recipe: {
          include: {
            author: {
              select: { id: true, username: true, email: true }
            }
          }
        }
      }
    });

    const duration = Date.now() - startTime;
    Logger.api('POST', `/api/favorites/${recipeId}`, 201, userId, duration);
    Logger.info(`Recipe added to favorites`, {
      context: 'FAVORITE',
      userId,
      recipeId,
      recipeTitle: favorite.recipe.title,
      durationMs: duration
    });
    
    res.status(201).json({
      message: 'Ricetta aggiunta ai preferiti',
      favorite
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    Logger.error('Errore nell\'aggiunta ai preferiti', error, {
      context: 'FAVORITE',
      endpoint: `/api/favorites/${req.params.recipeId}`,
      durationMs: duration
    });
    res.status(500).json({ error: 'Errore nell\'aggiunta ai preferiti' });
  }
});

// DELETE /api/favorites/:recipeId - Rimuovi dai preferiti
router.delete('/:recipeId', async (req: any, res) => {
  const startTime = Date.now();
  
  try {
    const userId = req.user.userId;
    const { recipeId } = req.params;

    Logger.api('DELETE', `/api/favorites/${recipeId}`, undefined, userId);
    Logger.db('DELETE favorite', 'Favorite', { userId, recipeId });
    
    // Verifica che il preferito esista
    const favorite = await prisma.favorite.findUnique({
      where: {
        userId_recipeId: {
          userId,
          recipeId
        }
      }
    });

    if (!favorite) {
      Logger.warn(`Favorite not found`, {
        context: 'FAVORITE',
        userId,
        recipeId
      });
      return res.status(404).json({ error: 'Preferito non trovato' });
    }

    // Elimina il preferito
    await prisma.favorite.delete({
      where: {
        userId_recipeId: {
          userId,
          recipeId
        }
      }
    });

    const duration = Date.now() - startTime;
    Logger.api('DELETE', `/api/favorites/${recipeId}`, 200, userId, duration);
    Logger.info(`Recipe removed from favorites`, {
      context: 'FAVORITE',
      userId,
      recipeId,
      durationMs: duration
    });
    
    res.json({
      message: 'Ricetta rimossa dai preferiti'
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    Logger.error('Errore nella rimozione dai preferiti', error, {
      context: 'FAVORITE',
      endpoint: `/api/favorites/${req.params.recipeId}`,
      durationMs: duration
    });
    res.status(500).json({ error: 'Errore nella rimozione dai preferiti' });
  }
});

// GET /api/favorites/check/:recipeId - Controlla se è preferita
router.get('/check/:recipeId', async (req: any, res) => {
  const startTime = Date.now();
  
  try {
    const userId = req.user.userId;
    const { recipeId } = req.params;

    Logger.api('GET', `/api/favorites/check/${recipeId}`, undefined, userId);
    Logger.db('CHECK favorite', 'Favorite', { userId, recipeId });
    
    const favorite = await prisma.favorite.findUnique({
      where: {
        userId_recipeId: {
          userId,
          recipeId
        }
      }
    });

    const duration = Date.now() - startTime;
    Logger.api('GET', `/api/favorites/check/${recipeId}`, 200, userId, duration);
    
    res.json({
      isFavorite: !!favorite,
      favoritedAt: favorite?.createdAt
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    Logger.error('Errore nel controllo preferito', error, {
      context: 'FAVORITE',
      endpoint: `/api/favorites/check/${req.params.recipeId}`,
      durationMs: duration
    });
    res.status(500).json({ error: 'Errore nel controllo preferito' });
  }
});

export default router;