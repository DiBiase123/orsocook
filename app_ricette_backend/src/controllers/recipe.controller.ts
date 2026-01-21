import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AuthRequest } from '../middleware/auth';
import multer from 'multer';
import { uploadToMinIO } from '../utils/minio';
import slugify from 'slugify';
import fs from 'fs';
import path from 'path';

const prisma = new PrismaClient();

// ================================
// HELPER FUNCTIONS
// ================================

/**
 * Processa i tag: cerca quelli esistenti, crea quelli nuovi
 */
async function processTagsForRecipe(tags: any[]): Promise<{ id: string }[]> {
  if (!tags || tags.length === 0) {
    return [];
  }

  console.log('🔍 Processing tags:', tags);

  // Estrai nomi dei tag
  const tagNames = tags.map(tag => {
    if (typeof tag === 'string') {
      return tag.trim().toLowerCase();
    }
    if (tag && typeof tag === 'object') {
      if (tag.name) return tag.name.trim().toLowerCase();
      if (tag.tag && tag.tag.name) return tag.tag.name.trim().toLowerCase();
      if (tag.tag && typeof tag.tag === 'string') return tag.tag.trim().toLowerCase();
    }
    return '';
  }).filter(name => name !== '' && name !== null && name !== undefined);

  console.log('📋 Tag names extracted:', tagNames);

  // Cerca o crea ogni tag
  const processedTags = [];
  
  for (const tagName of tagNames) {
    try {
      // Cerca tag esistente
      let existingTag = await prisma.tag.findFirst({
        where: { name: tagName }
      });

      // Se non esiste, crealo
      if (!existingTag) {
        console.log(`➕ Creating new tag: ${tagName}`);
        existingTag = await prisma.tag.create({
          data: {
            name: tagName,
            slug: slugify(tagName, { lower: true })
          }
        });
      }

      processedTags.push({ id: existingTag.id });
    } catch (error) {
      console.error(`❌ Error processing tag "${tagName}":`, error);
    }
  }

  console.log('✅ Processed tags:', processedTags);
  return processedTags;
}

// ================================
// CONTROLLER FUNCTIONS
// ================================

/**
 * GET /api/recipes - Lista ricette
 */
export async function getRecipes(req: Request, res: Response) {
  try {
    const { page = 1, limit = 10, category, search } = req.query;
    const pageNum = parseInt(page as string);
    const limitNum = parseInt(limit as string);
    const skip = (pageNum - 1) * limitNum;

    // Costruisci il filtro WHERE
    const where: any = {};

    if (category) {
      where.category = {
        slug: category as string
      };
    }

    if (search) {
      where.OR = [
        { title: { contains: search as string, mode: 'insensitive' } },
        { description: { contains: search as string, mode: 'insensitive' } }
      ];
    }

    where.isPublic = true; // Solo ricette pubbliche

    // Conta totale
    const total = await prisma.recipe.count({ where });

    // Recupera ricette
    const recipes = await prisma.recipe.findMany({
      where,
      skip,
      take: limitNum,
      include: {
        author: {
          select: {
            id: true,
            username: true,
            email: true,
            avatarUrl: true
          }
        },
        category: {
          select: {
            id: true,
            name: true,
            slug: true
          }
        },
        tags: {
          include: {
            tag: true
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    // Conta likes e favorites per ogni ricetta
    const recipesWithCounts = await Promise.all(
      recipes.map(async (recipe) => {
        const [favoritesCount, likesCount] = await Promise.all([
          prisma.favorite.count({
            where: { recipeId: recipe.id }
          }),
          prisma.like.count({
            where: { recipeId: recipe.id }
          })
        ]);

        return {
          ...recipe,
          favoriteCount: favoritesCount,
          likeCount: likesCount,
          isFavorite: false, // Sarà popolato dal frontend se l'utente è loggato
          isLiked: false     // Sarà popolato dal frontend se l'utente è loggato
        };
      })
    );

    res.status(200).json({
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
    console.error('❌ Error fetching recipes:', error);
    res.status(500).json({
      success: false,
      message: 'Errore nel caricamento delle ricette',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

/**
 * GET /api/recipes/:id - Dettaglio ricetta
 */
export async function getRecipeById(req: Request, res: Response) {
  try {
    const { id } = req.params;

    // Incrementa il contatore delle visualizzazioni
    const recipe = await prisma.recipe.findUnique({
      where: { id }
    });

    if (recipe) {
      await prisma.recipe.update({
        where: { id },
        data: {
          views: recipe.views + 1
        }
      });
    }

    const recipeWithDetails = await prisma.recipe.findUnique({
      where: { id },
      include: {
        author: {
          select: {
            id: true,
            username: true,
            email: true,
            avatarUrl: true
          }
        },
        category: {
          select: {
            id: true,
            name: true,
            slug: true
          }
        },
        tags: {
          include: {
            tag: true
          }
        }
      }
    });

    if (!recipeWithDetails) {
      return res.status(404).json({
        success: false,
        message: 'Ricetta non trovata'
      });
    }

    // Conta likes e favorites
    const [favoritesCount, likesCount] = await Promise.all([
      prisma.favorite.count({
        where: { recipeId: id }
      }),
      prisma.like.count({
        where: { recipeId: id }
      })
    ]);

    // Formatta la risposta
    const formattedRecipe = {
      ...recipeWithDetails,
      favoriteCount: favoritesCount,
      likeCount: likesCount,
      isFavorite: false,
      isLiked: false
    };

    res.status(200).json({
      success: true,
      data: formattedRecipe
    });
  } catch (error) {
    console.error('❌ Error fetching recipe:', error);
    res.status(500).json({
      success: false,
      message: 'Errore nel caricamento della ricetta',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

/**
 * POST /api/recipes - Crea nuova ricetta
 */
export async function createRecipe(req: AuthRequest, res: Response) {
  try {
    const {
      title,
      description,
      prepTime,
      cookTime,
      servings,
      difficulty,
      isPublic = true,
      categoryId,
      ingredients = [],
      instructions = [],
      tags = []
    } = req.body;

    console.log('📦 Request body:', {
      title,
      description,
      ingredients,
      instructions,
      tags
    });

    // Validazioni
    if (!title || !description) {
      return res.status(400).json({
        success: false,
        message: 'Titolo e descrizione sono obbligatori'
      });
    }

    // Crea slug unico
    const baseSlug = slugify(title, { lower: true });
    const uniqueSlug = `${baseSlug}-${Date.now()}`;

    // Gestione immagine
    let imageUrl: string | undefined;
    if (req.file) {
      try {
        const uploadResult = await uploadToMinIO(req.file, 'recipes');
        imageUrl = uploadResult.url;
        
        // Cancella il file temporaneo
        fs.unlinkSync(req.file.path);
      } catch (uploadError) {
        console.error('❌ Error uploading image:', uploadError);
        return res.status(500).json({
          success: false,
          message: 'Errore nel caricamento dell\'immagine'
        });
      }
    }

    console.log('🏗️ Creating recipe with tags:', tags);

    // 1. Crea la ricetta
    const recipe = await prisma.recipe.create({
      data: {
        title,
        description,
        slug: uniqueSlug,
        imageUrl,
        prepTime: parseInt(prepTime) || 0,
        cookTime: parseInt(cookTime) || 0,
        servings: parseInt(servings) || 1,
        difficulty,
        isPublic: isPublic === 'true' || isPublic === true,
        ingredients: ingredients, // Salva come JSON direttamente
        instructions: instructions, // Salva come JSON direttamente
        author: {
          connect: { id: req.user.id }
        },
        category: categoryId ? {
          connect: { id: categoryId }
        } : undefined
      },
      include: {
        author: {
          select: {
            id: true,
            username: true,
            email: true,
            avatarUrl: true
          }
        },
        category: {
          select: {
            id: true,
            name: true,
            slug: true
          }
        },
        tags: {
          include: {
            tag: true
          }
        }
      }
    });

    console.log('✅ Recipe created:', recipe.id);

    // 2. Processa e collega i tag (se presenti)
    if (tags && tags.length > 0) {
      try {
        const processedTags = await processTagsForRecipe(tags);
        
        if (processedTags.length > 0) {
          console.log(`🔗 Connecting ${processedTags.length} tags to recipe`);
          
          // Crea le associazioni tra recipe e tag
          const tagConnections = processedTags.map(tag => ({
            recipeId: recipe.id,
            tagId: tag.id
          }));

          await prisma.recipeTag.createMany({
            data: tagConnections
          });

          console.log('✅ Tags connected successfully');
        }
      } catch (tagError) {
        console.error('❌ Error processing tags:', tagError);
        // Non blocchiamo la risposta se i tag falliscono
      }
    }

    // 3. Ritorna la ricetta completa con tag
    const recipeWithTags = await prisma.recipe.findUnique({
      where: { id: recipe.id },
      include: {
        author: {
          select: {
            id: true,
            username: true,
            email: true,
            avatarUrl: true
          }
        },
        category: {
          select: {
            id: true,
            name: true,
            slug: true
          }
        },
        tags: {
          include: {
            tag: true
          }
        }
      }
    });

    if (!recipeWithTags) {
      return res.status(500).json({
        success: false,
        message: 'Errore nel recupero della ricetta creata'
      });
    }

    // Conta likes e favorites (saranno 0 per nuova ricetta)
    const [favoritesCount, likesCount] = await Promise.all([
      prisma.favorite.count({
        where: { recipeId: recipe.id }
      }),
      prisma.like.count({
        where: { recipeId: recipe.id }
      })
    ]);

    // Formatta la risposta
    const formattedRecipe = {
      ...recipeWithTags,
      favoriteCount: favoritesCount,
      likeCount: likesCount,
      isFavorite: false,
      isLiked: false
    };

    console.log('🎉 Recipe creation completed successfully');

    res.status(201).json({
      success: true,
      message: 'Ricetta creata con successo',
      data: formattedRecipe
    });
  } catch (error) {
    console.error('❌ Error creating recipe:', error);
    
    // Cancella l'immagine se è stata caricata ma la ricetta non è stata creata
    if (req.file && req.file.path) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (fsError) {
        console.error('Error deleting temp file:', fsError);
      }
    }

    res.status(500).json({
      success: false,
      message: 'Errore nella creazione della ricetta',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

/**
 * PUT /api/recipes/:id - Modifica ricetta
 */
export async function updateRecipe(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;
    const {
      title,
      description,
      prepTime,
      cookTime,
      servings,
      difficulty,
      isPublic,
      categoryId,
      ingredients,
      instructions,
      tags
    } = req.body;

    console.log('🔄 Updating recipe:', id);
    console.log('📦 Update data:', {
      title,
      description,
      ingredients,
      instructions,
      tags
    });

    // Verifica che la ricetta esista e appartenga all'utente
    const existingRecipe = await prisma.recipe.findUnique({
      where: { id },
      include: { author: true }
    });

    if (!existingRecipe) {
      return res.status(404).json({
        success: false,
        message: 'Ricetta non trovata'
      });
    }

    if (existingRecipe.authorId !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Non hai i permessi per modificare questa ricetta'
      });
    }

    // Preparare i dati per l'aggiornamento
    const updateData: any = {};

    if (title !== undefined) updateData.title = title;
    if (description !== undefined) updateData.description = description;
    if (prepTime !== undefined) updateData.prepTime = parseInt(prepTime);
    if (cookTime !== undefined) updateData.cookTime = parseInt(cookTime);
    if (servings !== undefined) updateData.servings = parseInt(servings);
    if (difficulty !== undefined) updateData.difficulty = difficulty;
    if (isPublic !== undefined) updateData.isPublic = isPublic === 'true' || isPublic === true;
    if (categoryId !== undefined) {
      updateData.category = categoryId 
        ? { connect: { id: categoryId } }
        : { disconnect: true };
    }
    if (ingredients !== undefined) updateData.ingredients = ingredients;
    if (instructions !== undefined) updateData.instructions = instructions;

    // Gestione immagine
    if (req.file) {
      try {
        // Cancella l'immagine vecchia se esiste
        if (existingRecipe.imageUrl) {
          try {
            // Potresti voler implementare la cancellazione da MinIO qui
          } catch (deleteError) {
            console.error('Error deleting old image:', deleteError);
          }
        }

        // Carica la nuova immagine
        const uploadResult = await uploadToMinIO(req.file, 'recipes');
        updateData.imageUrl = uploadResult.url;
        
        // Cancella il file temporaneo
        fs.unlinkSync(req.file.path);
      } catch (uploadError) {
        console.error('❌ Error uploading image:', uploadError);
        return res.status(500).json({
          success: false,
          message: 'Errore nel caricamento dell\'immagine'
        });
      }
    }

    // 1. Aggiorna la ricetta base
    const updatedRecipe = await prisma.recipe.update({
      where: { id },
      data: updateData
    });

    // 2. Aggiorna tag se forniti
    if (tags !== undefined) {
      console.log('🔄 Processing tags for update:', tags);
      
      // Cancella vecchie associazioni tag
      await prisma.recipeTag.deleteMany({
        where: { recipeId: id }
      });

      // Processa e collega i nuovi tag (se presenti)
      if (tags.length > 0) {
        const processedTags = await processTagsForRecipe(tags);
        
        if (processedTags.length > 0) {
          // Crea nuove associazioni
          const tagConnections = processedTags.map(tag => ({
            recipeId: id,
            tagId: tag.id
          }));

          await prisma.recipeTag.createMany({
            data: tagConnections
          });
        }
      }
    }

    // 3. Recupera la ricetta completa aggiornata
    const completeRecipe = await prisma.recipe.findUnique({
      where: { id },
      include: {
        author: {
          select: {
            id: true,
            username: true,
            email: true,
            avatarUrl: true
          }
        },
        category: {
          select: {
            id: true,
            name: true,
            slug: true
          }
        },
        tags: {
          include: {
            tag: true
          }
        }
      }
    });

    if (!completeRecipe) {
      return res.status(500).json({
        success: false,
        message: 'Errore nel recupero della ricetta aggiornata'
      });
    }

    // Conta likes e favorites
    const [favoritesCount, likesCount] = await Promise.all([
      prisma.favorite.count({
        where: { recipeId: id }
      }),
      prisma.like.count({
        where: { recipeId: id }
      })
    ]);

    // Formatta la risposta
    const formattedRecipe = {
      ...completeRecipe,
      favoriteCount: favoritesCount,
      likeCount: likesCount,
      isFavorite: false,
      isLiked: false
    };

    res.status(200).json({
      success: true,
      message: 'Ricetta aggiornata con successo',
      data: formattedRecipe
    });
  } catch (error) {
    console.error('❌ Error updating recipe:', error);
    res.status(500).json({
      success: false,
      message: 'Errore nell\'aggiornamento della ricetta',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

/**
 * DELETE /api/recipes/:id - Elimina ricetta
 */
export async function deleteRecipe(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;

    // Verifica che la ricetta esista e appartenga all'utente
    const existingRecipe = await prisma.recipe.findUnique({
      where: { id },
      include: { author: true }
    });

    if (!existingRecipe) {
      return res.status(404).json({
        success: false,
        message: 'Ricetta non trovata'
      });
    }

    if (existingRecipe.authorId !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Non hai i permessi per eliminare questa ricetta'
      });
    }

    // Elimina la ricetta (le relazioni verranno eliminate in cascata)
    await prisma.recipe.delete({
      where: { id }
    });

    res.status(200).json({
      success: true,
      message: 'Ricetta eliminata con successo'
    });
  } catch (error) {
    console.error('❌ Error deleting recipe:', error);
    res.status(500).json({
      success: false,
      message: 'Errore nell\'eliminazione della ricetta',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

/**
 * GET /api/recipes/user/:userId - Ricette di un utente
 */
export async function getUserRecipes(req: AuthRequest, res: Response) {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 10 } = req.query;
    const pageNum = parseInt(page as string);
    const limitNum = parseInt(limit as string);
    const skip = (pageNum - 1) * limitNum;

    // Conta totale
    const total = await prisma.recipe.count({
      where: { authorId: userId }
    });

    // Recupera ricette
    const recipes = await prisma.recipe.findMany({
      where: { authorId: userId },
      skip,
      take: limitNum,
      include: {
        author: {
          select: {
            id: true,
            username: true,
            email: true,
            avatarUrl: true
          }
        },
        category: {
          select: {
            id: true,
            name: true,
            slug: true
          }
        },
        tags: {
          include: {
            tag: true
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    // Conta likes e favorites per ogni ricetta
    const recipesWithCounts = await Promise.all(
      recipes.map(async (recipe) => {
        const [favoritesCount, likesCount] = await Promise.all([
          prisma.favorite.count({
            where: { recipeId: recipe.id }
          }),
          prisma.like.count({
            where: { recipeId: recipe.id }
          })
        ]);

        return {
          ...recipe,
          favoriteCount: favoritesCount,
          likeCount: likesCount,
          isFavorite: false,
          isLiked: false
        };
      })
    );

    res.status(200).json({
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
    console.error('❌ Error fetching user recipes:', error);
    res.status(500).json({
      success: false,
      message: 'Errore nel caricamento delle ricette dell\'utente',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

// ================================
// LIKE FUNCTIONS
// ================================

/**
 * GET /api/recipes/:id/likes - Conta likes di una ricetta
 */
export async function getRecipeLikesCount(req: Request, res: Response) {
  try {
    const { id } = req.params;

    const count = await prisma.like.count({
      where: { recipeId: id }
    });

    res.status(200).json({
      success: true,
      data: { count }
    });
  } catch (error) {
    console.error('❌ Error getting likes count:', error);
    res.status(500).json({
      success: false,
      message: 'Errore nel recupero del conteggio likes',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

/**
 * GET /api/recipes/:id/liked - Verifica se l'utente ha messo like
 */
export async function checkRecipeLiked(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;

    const like = await prisma.like.findUnique({
      where: {
        userId_recipeId: {
          userId: req.user.id,
          recipeId: id
        }
      }
    });

    res.status(200).json({
      success: true,
      data: { liked: !!like }
    });
  } catch (error) {
    console.error('❌ Error checking if liked:', error);
    res.status(500).json({
      success: false,
      message: 'Errore nella verifica del like',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

/**
 * POST /api/recipes/:id/like - Aggiungi like
 */
export async function addLikeToRecipe(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;

    // PRIMA controlla se esiste già
    const existingLike = await prisma.like.findUnique({
      where: {
        userId_recipeId: {
          userId: req.user.id,
          recipeId: id
        }
      }
    });

    // Se già esiste, ritorna successo
    if (existingLike) {
      return res.status(200).json({
        success: true,
        message: 'Like già presente',
        data: { liked: true }
      });
    }

    // Altrimenti, crea il like
    const like = await prisma.like.create({
      data: {
        userId: req.user.id,
        recipeId: id
      }
    });

    res.status(201).json({
      success: true,
      message: 'Like aggiunto',
      data: { liked: true }
    });
  } catch (error) {
    console.error('❌ Error adding like:', error);
    
    // Se è già presente (doppio click), considera comunque successo
    if ((error as any).code === 'P2002') {
      return res.status(200).json({
        success: true,
        message: 'Like già presente',
        data: { liked: true }
      });
    }

    res.status(500).json({
      success: false,
      message: 'Errore nell\'aggiunta del like',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

/**
 * DELETE /api/recipes/:id/like - Rimuovi like
 */
export async function removeLikeFromRecipe(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;

    await prisma.like.delete({
      where: {
        userId_recipeId: {
          userId: req.user.id,
          recipeId: id
        }
      }
    });

    res.status(200).json({
      success: true,
      message: 'Like rimosso',
      data: { liked: false } // ✅ MODIFICA: Ritorna { liked: false }
    });
  } catch (error) {
    console.error('❌ Error removing like:', error);
    
    // Se non esiste, considera comunque successo
    if ((error as any).code === 'P2025') {
      return res.status(200).json({
        success: true,
        message: 'Like non presente',
        data: { liked: false } // ✅ MODIFICA: Ritorna { liked: false }
      });
    }

    res.status(500).json({
      success: false,
      message: 'Errore nella rimozione del like',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

// ================================
// FAVORITE FUNCTIONS (se ancora servono)
// ================================

/**
 * GET /api/favorites/check/:recipeId - Verifica se la ricetta è nei preferiti
 */
export async function checkRecipeFavorite(req: AuthRequest, res: Response) {
  try {
    const { recipeId } = req.params;

    const favorite = await prisma.favorite.findUnique({
      where: {
        userId_recipeId: {
          userId: req.user.id,
          recipeId: recipeId
        }
      }
    });

    res.status(200).json({
      success: true,
      data: { isFavorite: !!favorite }
    });
  } catch (error) {
    console.error('❌ Error checking favorite:', error);
    res.status(500).json({
      success: false,
      message: 'Errore nella verifica del preferito',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

/**
 * POST /api/recipes/:id/upload-image - Upload immagine per ricetta esistente
 */
export async function uploadRecipeImage(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;
    
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Nessun file immagine fornito'
      });
    }

    // Verifica che la ricetta esista e appartenga all'utente
    const existingRecipe = await prisma.recipe.findUnique({
      where: { id },
      include: { author: true }
    });

    if (!existingRecipe) {
      return res.status(404).json({
        success: false,
        message: 'Ricetta non trovata'
      });
    }

    if (existingRecipe.authorId !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Non hai i permessi per modificare questa ricetta'
      });
    }

    // Upload a MinIO
    const uploadResult = await uploadToMinIO(req.file, 'recipes');
    
    // Aggiorna ricetta con imageUrl
    await prisma.recipe.update({
      where: { id },
      data: { imageUrl: uploadResult.url }
    });

    res.status(200).json({
      success: true,
      message: 'Immagine caricata con successo',
      data: { imageUrl: uploadResult.url } // ✅ MODIFICA: Ritorna solo imageUrl
    });
  } catch (error) {
    console.error('❌ Error uploading recipe image:', error);
    res.status(500).json({
      success: false,
      message: 'Errore nel caricamento dell\'immagine',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

// ================================
// COMMENT FUNCTIONS
// ================================

/**
 * GET /api/recipes/:id/comments - Lista commenti di una ricetta
 */
export async function getRecipeComments(req: Request, res: Response) {
  try {
    const { id: recipeId } = req.params;

    const comments = await prisma.comment.findMany({
      where: { recipeId },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true,
            avatarUrl: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.status(200).json({
      success: true,
      data: comments,
    });
  } catch (error) {
    console.error('❌ Error fetching recipe comments:', error);
    res.status(500).json({
      success: false,
      message: 'Errore nel recupero dei commenti',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

/**
 * POST /api/recipes/:id/comments - Crea nuovo commento
 */
export async function createComment(req: AuthRequest, res: Response) {
  try {
    const { id: recipeId } = req.params;
    const { content } = req.body;
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Utente non autenticato',
      });
    }

    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Il contenuto del commento è obbligatorio',
      });
    }

    if (content.length > 1000) {
      return res.status(400).json({
        success: false,
        message: 'Il commento non può superare i 1000 caratteri',
      });
    }

    // Verifica che la ricetta esista
    const recipe = await prisma.recipe.findUnique({
      where: { id: recipeId },
    });

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Ricetta non trovata',
      });
    }

    // Crea commento in una transaction per aggiornare commentCount
    const [comment] = await prisma.$transaction([
      prisma.comment.create({
        data: {
          content: content.trim(),
          recipeId,
          userId,
        },
        include: {
          user: {
            select: {
              id: true,
              username: true,
              email: true,
              avatarUrl: true,
            },
          },
        },
      }),
      prisma.recipe.update({
        where: { id: recipeId },
        data: {
          commentCount: {
            increment: 1,
          },
        },
      }),
    ]);

    res.status(201).json({
      success: true,
      message: 'Commento aggiunto con successo',
      data: comment,
    });
  } catch (error) {
    console.error('❌ Error creating comment:', error);
    res.status(500).json({
      success: false,
      message: 'Errore nella creazione del commento',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

/**
 * PUT /api/comments/:commentId - Modifica commento
 */
export async function updateComment(req: AuthRequest, res: Response) {
  try {
    const { commentId } = req.params;
    const { content } = req.body;
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Utente non autenticato',
      });
    }

    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Il contenuto del commento è obbligatorio',
      });
    }

    if (content.length > 1000) {
      return res.status(400).json({
        success: false,
        message: 'Il commento non può superare i 1000 caratteri',
      });
    }

    // Trova il commento
    const comment = await prisma.comment.findUnique({
      where: { id: commentId },
    });

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: 'Commento non trovato',
      });
    }

    // Verifica proprietà
    if (comment.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Non autorizzato a modificare questo commento',
      });
    }

    // Aggiorna commento
    const updatedComment = await prisma.comment.update({
      where: { id: commentId },
      data: {
        content: content.trim(),
        isEdited: true,
      },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true,
            avatarUrl: true,
          },
        },
      },
    });

    res.status(200).json({
      success: true,
      message: 'Commento aggiornato con successo',
      data: updatedComment,
    });
  } catch (error) {
    console.error('❌ Error updating comment:', error);
    res.status(500).json({
      success: false,
      message: 'Errore nell\'aggiornamento del commento',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

/**
 * DELETE /api/comments/:commentId - Elimina commento
 */
export async function deleteComment(req: AuthRequest, res: Response) {
  try {
    const { commentId } = req.params;
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Utente non autenticato',
      });
    }

    // Trova il commento con info della ricetta
    const comment = await prisma.comment.findUnique({
      where: { id: commentId },
      include: {
        recipe: {
          select: { id: true },
        },
      },
    });

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: 'Commento non trovato',
      });
    }

    // Verifica proprietà
    if (comment.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Non autorizzato a eliminare questo commento',
      });
    }

    // Elimina commento in una transaction per aggiornare commentCount
    await prisma.$transaction([
      prisma.comment.delete({
        where: { id: commentId },
      }),
      prisma.recipe.update({
        where: { id: comment.recipe.id },
        data: {
          commentCount: {
            decrement: 1,
          },
        },
      }),
    ]);

    res.status(200).json({
      success: true,
      message: 'Commento eliminato con successo',
    });
  } catch (error) {
    console.error('❌ Error deleting comment:', error);
    res.status(500).json({
      success: false,
      message: 'Errore nell\'eliminazione del commento',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}