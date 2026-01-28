import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AuthRequest } from '../middleware/auth';
import slugify from 'slugify';
import { uploadImageToCloudinary } from '../services/cloudinary.service';
import Logger from '../utils/logger';

const prisma = new PrismaClient();

// Helper: Process tags
async function processTags(tags: any[]): Promise<{ id: string }[]> {
  if (!tags?.length) return [];

  const tagNames = tags
    .map(tag => {
      if (typeof tag === 'string') return tag.trim().toLowerCase();
      if (tag?.name) return tag.name.trim().toLowerCase();
      if (tag?.tag?.name) return tag.tag.name.trim().toLowerCase();
      if (tag?.tag && typeof tag.tag === 'string') return tag.tag.trim().toLowerCase();
      return '';
    })
    .filter(name => name);

  const processedTags = [];
  for (const name of tagNames) {
    try {
      let tag = await prisma.tag.findFirst({ where: { name } });
      if (!tag) {
        tag = await prisma.tag.create({
          data: { name, slug: slugify(name, { lower: true }) }
        });
      }
      processedTags.push({ id: tag.id });
    } catch (error) {
      Logger.error(`Error processing tag "${name}"`, error);
    }
  }
  return processedTags;
}

// Helper: Get recipe with counts
async function getRecipeWithCounts(id: string) {
  const recipe = await prisma.recipe.findUnique({
    where: { id },
    include: {
      author: { select: { id: true, username: true, email: true, avatarUrl: true } },
      category: { select: { id: true, name: true, slug: true } },
      tags: { include: { tag: true } }
    }
  });

  if (!recipe) return null;

  const [favoriteCount, likeCount] = await Promise.all([
    prisma.favorite.count({ where: { recipeId: id } }),
    prisma.like.count({ where: { recipeId: id } })
  ]);

  return {
    ...recipe,
    favoriteCount,
    likeCount,
    isFavorite: false,
    isLiked: false
  };
}

// Helper: Upload image
async function uploadImage(
  fileBuffer: Buffer, 
  mimetype?: string, 
  filename?: string
): Promise<string> {
  return await uploadImageToCloudinary(
    fileBuffer, 
    'orsocook/recipes', 
    mimetype, 
    filename
  );
}

// GET /api/recipes
export async function getRecipes(req: Request, res: Response) {
  try {
    const { page = 1, limit = 10, category, search } = req.query;
    const pageNum = Number(page) || 1;
    const limitNum = Number(limit) || 10;
    const skip = (pageNum - 1) * limitNum;

    const where: any = { isPublic: true };
    if (category) where.category = { slug: String(category) };
    if (search) {
      where.OR = [
        { title: { contains: String(search), mode: 'insensitive' } },
        { description: { contains: String(search), mode: 'insensitive' } }
      ];
    }

    const [total, recipes] = await Promise.all([
      prisma.recipe.count({ where }),
      prisma.recipe.findMany({
        where,
        skip,
        take: limitNum,
        include: {
          author: { select: { id: true, username: true, email: true, avatarUrl: true } },
          category: { select: { id: true, name: true, slug: true } },
          tags: { include: { tag: true } }
        },
        orderBy: { createdAt: 'desc' }
      })
    ]);

    const recipesWithCounts = await Promise.all(
      recipes.map(async recipe => {
        const [favoriteCount, likeCount] = await Promise.all([
          prisma.favorite.count({ where: { recipeId: recipe.id } }),
          prisma.like.count({ where: { recipeId: recipe.id } })
        ]);

        return {
          ...recipe,
          favoriteCount,
          likeCount,
          isFavorite: false,
          isLiked: false
        };
      })
    );

    res.json({
      success: true,
      data: {
        recipes: recipesWithCounts,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total,
          pages: Math.ceil(total / limitNum)
        }
      }
    });
  } catch (error) {
    Logger.error('Error fetching recipes', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nel caricamento delle ricette',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}

// GET /api/recipes/:id
export async function getRecipeById(req: Request, res: Response) {
  try {
    const { id } = req.params;

    // Increment views
    await prisma.recipe.update({
      where: { id },
      data: { views: { increment: 1 } }
    });

    const recipe = await getRecipeWithCounts(id);
    if (!recipe) {
      return res.status(404).json({ success: false, message: 'Ricetta non trovata' });
    }

    res.json({ success: true, data: recipe });
  } catch (error) {
    Logger.error('Error fetching recipe', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nel caricamento della ricetta',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}

// POST /api/recipes
export async function createRecipe(req: AuthRequest, res: Response) {
  try {
    Logger.debug('Creating recipe', { userId: req.user.id });
    
    const { 
      title, description, prepTime, cookTime, servings, difficulty,
      isPublic = true, categoryId, ingredients = [], instructions = [], tags = [] 
    } = req.body;

    if (!title || !description) {
      return res.status(400).json({ 
        success: false, 
        message: 'Titolo e descrizione sono obbligatori' 
      });
    }

    const baseSlug = slugify(title, { lower: true });
    const uniqueSlug = `${baseSlug}-${Date.now()}`;

    let imageUrl: string | undefined;
    if (req.file?.buffer) {
      try {
        Logger.debug('Uploading image for recipe');
        imageUrl = await uploadImage(
          req.file.buffer, 
          req.file.mimetype, 
          req.file.originalname
        );
      } catch (error) {
        Logger.error('Error uploading image', error);
        return res.status(500).json({ 
          success: false, 
          message: 'Errore nel caricamento dell\'immagine',
          details: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
        });
      }
    }

    const recipe = await prisma.recipe.create({
      data: {
        title,
        description,
        slug: uniqueSlug,
        imageUrl,
        prepTime: Number(prepTime) || 0,
        cookTime: Number(cookTime) || 0,
        servings: Number(servings) || 1,
        difficulty,
        isPublic: isPublic === 'true' || isPublic === true,
        ingredients,
        instructions,
        author: { connect: { id: req.user.id } },
        category: categoryId ? { connect: { id: categoryId } } : undefined
      }
    });

    if (tags?.length) {
      const processedTags = await processTags(tags);
      if (processedTags.length) {
        await prisma.recipeTag.createMany({
          data: processedTags.map(tag => ({
            recipeId: recipe.id,
            tagId: tag.id
          }))
        });
      }
    }

    const completeRecipe = await getRecipeWithCounts(recipe.id);
    if (!completeRecipe) {
      return res.status(500).json({ 
        success: false, 
        message: 'Errore nel recupero della ricetta creata' 
      });
    }

    Logger.info('Recipe created', { recipeId: recipe.id, userId: req.user.id });
    
    res.status(201).json({
      success: true,
      message: 'Ricetta creata con successo',
      data: completeRecipe
    });
  } catch (error) {
    Logger.error('Error creating recipe', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nella creazione della ricetta',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}

// PUT /api/recipes/:id
export async function updateRecipe(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;
    Logger.debug('Updating recipe', { recipeId: id, userId: req.user.id });
    
    const { 
      title, description, prepTime, cookTime, servings, difficulty,
      isPublic, categoryId, ingredients, instructions, tags 
    } = req.body;

    const existingRecipe = await prisma.recipe.findUnique({
      where: { id },
      include: { author: true }
    });

    if (!existingRecipe) {
      return res.status(404).json({ success: false, message: 'Ricetta non trovata' });
    }

    if (existingRecipe.authorId !== req.user.id) {
      return res.status(403).json({ 
        success: false, 
        message: 'Non hai i permessi per modificare questa ricetta' 
      });
    }

    const updateData: any = {};
    if (title !== undefined) updateData.title = title;
    if (description !== undefined) updateData.description = description;
    if (prepTime !== undefined) updateData.prepTime = Number(prepTime);
    if (cookTime !== undefined) updateData.cookTime = Number(cookTime);
    if (servings !== undefined) updateData.servings = Number(servings);
    if (difficulty !== undefined) updateData.difficulty = difficulty;
    if (isPublic !== undefined) updateData.isPublic = isPublic === 'true' || isPublic === true;
    
    if (categoryId !== undefined) {
      updateData.category = categoryId 
        ? { connect: { id: categoryId } }
        : { disconnect: true };
    }
    
    if (ingredients !== undefined) updateData.ingredients = ingredients;
    if (instructions !== undefined) updateData.instructions = instructions;

    if (req.file?.buffer) {
      try {
        Logger.debug('Uploading new image for recipe', { recipeId: id });
        updateData.imageUrl = await uploadImage(
          req.file.buffer, 
          req.file.mimetype, 
          req.file.originalname
        );
      } catch (error) {
        Logger.error('Error uploading image', error);
        return res.status(500).json({ 
          success: false, 
          message: 'Errore nel caricamento dell\'immagine',
          details: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
        });
      }
    }

    await prisma.recipe.update({ where: { id }, data: updateData });

    if (tags !== undefined) {
      await prisma.recipeTag.deleteMany({ where: { recipeId: id } });
      
      if (tags?.length) {
        const processedTags = await processTags(tags);
        if (processedTags.length) {
          await prisma.recipeTag.createMany({
            data: processedTags.map(tag => ({
              recipeId: id,
              tagId: tag.id
            }))
          });
        }
      }
    }

    const updatedRecipe = await getRecipeWithCounts(id);
    if (!updatedRecipe) {
      return res.status(500).json({ 
        success: false, 
        message: 'Errore nel recupero della ricetta aggiornata' 
      });
    }

    Logger.info('Recipe updated', { recipeId: id, userId: req.user.id });
    
    res.json({
      success: true,
      message: 'Ricetta aggiornata con successo',
      data: updatedRecipe
    });
  } catch (error) {
    Logger.error('Error updating recipe', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nell\'aggiornamento della ricetta',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}

// DELETE /api/recipes/:id
export async function deleteRecipe(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;

    const existingRecipe = await prisma.recipe.findUnique({
      where: { id },
      include: { author: true }
    });

    if (!existingRecipe) {
      return res.status(404).json({ success: false, message: 'Ricetta non trovata' });
    }

    if (existingRecipe.authorId !== req.user.id) {
      return res.status(403).json({ 
        success: false, 
        message: 'Non hai i permessi per eliminare questa ricetta' 
      });
    }

    await prisma.recipe.delete({ where: { id } });

    Logger.info('Recipe deleted', { recipeId: id, userId: req.user.id });
    
    res.json({ success: true, message: 'Ricetta eliminata con successo' });
  } catch (error) {
    Logger.error('Error deleting recipe', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nell\'eliminazione della ricetta',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}

// GET /api/recipes/user/:userId
export async function getUserRecipes(req: AuthRequest, res: Response) {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 10 } = req.query;
    const pageNum = Number(page) || 1;
    const limitNum = Number(limit) || 10;
    const skip = (pageNum - 1) * limitNum;

    const [total, recipes] = await Promise.all([
      prisma.recipe.count({ where: { authorId: userId } }),
      prisma.recipe.findMany({
        where: { authorId: userId },
        skip,
        take: limitNum,
        include: {
          author: { select: { id: true, username: true, email: true, avatarUrl: true } },
          category: { select: { id: true, name: true, slug: true } },
          tags: { include: { tag: true } }
        },
        orderBy: { createdAt: 'desc' }
      })
    ]);

    const recipesWithCounts = await Promise.all(
      recipes.map(async recipe => {
        const [favoriteCount, likeCount] = await Promise.all([
          prisma.favorite.count({ where: { recipeId: recipe.id } }),
          prisma.like.count({ where: { recipeId: recipe.id } })
        ]);

        return {
          ...recipe,
          favoriteCount,
          likeCount,
          isFavorite: false,
          isLiked: false
        };
      })
    );

    res.json({
      success: true,
      data: {
        recipes: recipesWithCounts,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total,
          pages: Math.ceil(total / limitNum)
        }
      }
    });
  } catch (error) {
    Logger.error('Error fetching user recipes', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nel caricamento delle ricette dell\'utente',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}

// POST /api/recipes/:id/upload-image
export async function uploadRecipeImage(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;
    
    if (!req.file?.buffer) {
      return res.status(400).json({ 
        success: false, 
        message: 'Nessun file immagine fornito' 
      });
    }

    const existingRecipe = await prisma.recipe.findUnique({
      where: { id },
      include: { author: true }
    });

    if (!existingRecipe) {
      return res.status(404).json({ success: false, message: 'Ricetta non trovata' });
    }

    if (existingRecipe.authorId !== req.user.id) {
      return res.status(403).json({ 
        success: false, 
        message: 'Non hai i permessi per modificare questa ricetta' 
      });
    }

    Logger.debug('Uploading recipe image', { recipeId: id, userId: req.user.id });
    
    const imageUrl = await uploadImage(
      req.file.buffer, 
      req.file.mimetype, 
      req.file.originalname
    );
    
    await prisma.recipe.update({
      where: { id },
      data: { imageUrl }
    });

    Logger.info('Recipe image uploaded', { recipeId: id, userId: req.user.id });
    
    res.json({
      success: true,
      message: 'Immagine caricata con successo',
      data: { imageUrl }
    });
  } catch (error) {
    Logger.error('Error uploading recipe image', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nel caricamento dell\'immagine',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}

// LIKE FUNCTIONS
export async function getRecipeLikesCount(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const count = await prisma.like.count({ where: { recipeId: id } });
    res.json({ success: true, data: { count } });
  } catch (error) {
    Logger.error('Error getting likes count', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nel recupero del conteggio likes',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}

export async function checkRecipeLiked(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;
    const like = await prisma.like.findUnique({
      where: { userId_recipeId: { userId: req.user.id, recipeId: id } }
    });
    res.json({ success: true, data: { liked: !!like } });
  } catch (error) {
    Logger.error('Error checking if liked', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nella verifica del like',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}

export async function addLikeToRecipe(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;

    try {
      await prisma.like.create({
        data: { userId: req.user.id, recipeId: id }
      });
    } catch (error: any) {
      if (error.code === 'P2002') {
        return res.json({ 
          success: true, 
          message: 'Like già presente',
          data: { liked: true } 
        });
      }
      throw error;
    }

    res.status(201).json({ 
      success: true, 
      message: 'Like aggiunto',
      data: { liked: true } 
    });
  } catch (error) {
    Logger.error('Error adding like', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nell\'aggiunta del like',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}

export async function removeLikeFromRecipe(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;

    try {
      await prisma.like.delete({
        where: { userId_recipeId: { userId: req.user.id, recipeId: id } }
      });
    } catch (error: any) {
      if (error.code === 'P2025') {
        return res.json({ 
          success: true, 
          message: 'Like non presente',
          data: { liked: false } 
        });
      }
      throw error;
    }

    res.json({ 
      success: true, 
      message: 'Like rimosso',
      data: { liked: false } 
    });
  } catch (error) {
    Logger.error('Error removing like', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nella rimozione del like',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}

export async function checkRecipeFavorite(req: AuthRequest, res: Response) {
  try {
    const { recipeId } = req.params;
    const favorite = await prisma.favorite.findUnique({
      where: { userId_recipeId: { userId: req.user.id, recipeId } }
    });
    res.json({ success: true, data: { isFavorite: !!favorite } });
  } catch (error) {
    Logger.error('Error checking favorite', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nella verifica del preferito',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}

// COMMENT FUNCTIONS
export async function getRecipeComments(req: Request, res: Response) {
  try {
    const { id: recipeId } = req.params;
    const comments = await prisma.comment.findMany({
      where: { recipeId },
      include: { user: { select: { id: true, username: true, email: true, avatarUrl: true } } },
      orderBy: { createdAt: 'desc' }
    });
    res.json({ success: true, data: comments });
  } catch (error) {
    Logger.error('Error fetching comments', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nel recupero dei commenti',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}

export async function createComment(req: AuthRequest, res: Response) {
  try {
    const { id: recipeId } = req.params;
    const { content } = req.body;
    const userId = req.user?.id;

    if (!userId) return res.status(401).json({ success: false, message: 'Utente non autenticato' });
    if (!content?.trim()) {
      return res.status(400).json({ 
        success: false, 
        message: 'Il contenuto del commento è obbligatorio' 
      });
    }
    if (content.length > 1000) {
      return res.status(400).json({ 
        success: false, 
        message: 'Il commento non può superare i 1000 caratteri' 
      });
    }

    const [comment] = await prisma.$transaction([
      prisma.comment.create({
        data: { content: content.trim(), recipeId, userId },
        include: { user: { select: { id: true, username: true, email: true, avatarUrl: true } } }
      }),
      prisma.recipe.update({
        where: { id: recipeId },
        data: { commentCount: { increment: 1 } }
      })
    ]);

    res.status(201).json({
      success: true,
      message: 'Commento aggiunto con successo',
      data: comment
    });
  } catch (error) {
    Logger.error('Error creating comment', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nella creazione del commento',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}

export async function updateComment(req: AuthRequest, res: Response) {
  try {
    const { commentId } = req.params;
    const { content } = req.body;
    const userId = req.user?.id;

    if (!userId) return res.status(401).json({ success: false, message: 'Utente non autenticato' });
    if (!content?.trim()) {
      return res.status(400).json({ 
        success: false, 
        message: 'Il contenuto del commento è obbligatorio' 
      });
    }

    const comment = await prisma.comment.findUnique({ where: { id: commentId } });
    if (!comment) return res.status(404).json({ success: false, message: 'Commento non trovato' });
    if (comment.userId !== userId) {
      return res.status(403).json({ 
        success: false, 
        message: 'Non autorizzato a modificare questo commento' 
      });
    }

    const updatedComment = await prisma.comment.update({
      where: { id: commentId },
      data: { content: content.trim(), isEdited: true },
      include: { user: { select: { id: true, username: true, email: true, avatarUrl: true } } }
    });

    res.json({
      success: true,
      message: 'Commento aggiornato con successo',
      data: updatedComment
    });
  } catch (error) {
    Logger.error('Error updating comment', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nell\'aggiornamento del commento',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}

export async function deleteComment(req: AuthRequest, res: Response) {
  try {
    const { commentId } = req.params;
    const userId = req.user?.id;

    if (!userId) return res.status(401).json({ success: false, message: 'Utente non autenticato' });

    const comment = await prisma.comment.findUnique({
      where: { id: commentId },
      include: { recipe: { select: { id: true } } }
    });

    if (!comment) return res.status(404).json({ success: false, message: 'Commento non trovato' });
    if (comment.userId !== userId) {
      return res.status(403).json({ 
        success: false, 
        message: 'Non autorizzato a eliminare questo commento' 
      });
    }

    await prisma.$transaction([
      prisma.comment.delete({ where: { id: commentId } }),
      prisma.recipe.update({
        where: { id: comment.recipe.id },
        data: { commentCount: { decrement: 1 } }
      })
    ]);

    res.json({ success: true, message: 'Commento eliminato con successo' });
  } catch (error) {
    Logger.error('Error deleting comment', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nell\'eliminazione del commento',
      error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
    });
  }
}