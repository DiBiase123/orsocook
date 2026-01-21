import express from 'express'
import { PrismaClient } from '@prisma/client'

const router = express.Router()
const prisma = new PrismaClient()

// GET /api/categories - Tutte le categorie
router.get('/', async (req, res) => {
  try {
    const categories = await prisma.category.findMany({
      include: {
        _count: {
          select: { recipes: true }
        }
      },
      orderBy: { name: 'asc' }
    })
    
    const categoriesWithCount = categories.map(cat => ({
      ...cat,
      recipeCount: cat._count.recipes,
      createdAt: cat.createdAt.toISOString(),
      updatedAt: cat.updatedAt.toISOString()
    }))
    
    // Rimuovi _count
    categoriesWithCount.forEach(cat => delete (cat as any)._count)
    
    res.json({
      success: true,
      data: categoriesWithCount
    })
    
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Errore interno del server'
    })
  }
})

export default router
