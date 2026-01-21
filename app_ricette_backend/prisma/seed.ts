import { PrismaClient, Role, Difficulty } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 Inizio seeding database...')

  // 1. PULISCI DATABASE (attento in produzione!)
  await prisma.favorite.deleteMany()
  await prisma.recipeTag.deleteMany()
  await prisma.follows.deleteMany()
  await prisma.recipe.deleteMany()
  await prisma.tag.deleteMany()
  await prisma.category.deleteMany()
  await prisma.user.deleteMany()

  // 2. CREA UTENTI
  const adminUser = await prisma.user.create({
    data: {
      email: 'admin_test@ricette.com',
      username: 'admin_test',
      passwordHash: '$2b$10$Es8g6z.7p6KJ5L2pQ6Z8OeX8QwL9mN1pOqR0sT3uVwXyZ1aB2cD3eF4g',
      displayName: 'Amministratore Test',
      role: Role.ADMIN,
      isVerified: true,
      bio: 'Amministratore del sito di ricette test'
    }
  })

  const normalUser = await prisma.user.create({
    data: {
      email: 'mario_test@ricette.com',
      username: 'mario_test',
      passwordHash: '$2b$10$Es8g6z.7p6KJ5L2pQ6Z8OeX8QwL9mN1pOqR0sT3uVwXyZ1aB2cD3eF4g',
      displayName: 'Mario Rossi Test',
      bio: 'Appassionato di cucina italiana test'
    }
  })

  console.log(`✅ Utenti creati: ${adminUser.username}, ${normalUser.username}`)

  // 3. CREA CATEGORIE
  const categories = await prisma.category.createMany({
    data: [
      { name: 'Antipasti_test', slug: 'antipasti-test', description: 'Antipasti italiani test' },
      { name: 'Primi Piatti_test', slug: 'primi-piatti-test', description: 'Primi piatti italiani test' },
      { name: 'Secondi Piatti_test', slug: 'secondi-piatti-test', description: 'Secondi piatti italiani test' },
      { name: 'Dolci_test', slug: 'dolci-test', description: 'Dolci italiani test' },
      { name: 'Contorni_test', slug: 'contorni-test', description: 'Contorni italiani test' },
    ]
  })

  const categorieList = await prisma.category.findMany()
  console.log(`✅ Categorie create: ${categorieList.length}`)

  // 4. CREA TAGS
  const tags = await prisma.tag.createMany({
    data: [
      { name: 'Vegano_test', slug: 'vegano-test' },
      { name: 'Vegetariano_test', slug: 'vegetariano-test' },
      { name: 'Veloce_test', slug: 'veloce-test' },
      { name: 'Economico_test', slug: 'economico-test' },
      { name: 'Piccante_test', slug: 'piccante-test' },
      { name: 'Senza Glutine_test', slug: 'senza-glutine-test' },
    ]
  })

  const tagsList = await prisma.tag.findMany()
  console.log(`✅ Tags creati: ${tagsList.length}`)

  // 5. CREA RICETTE
  const ricetta1 = await prisma.recipe.create({
    data: {
      title: 'Spaghetti Carbonara_test',
      slug: 'spaghetti-carbonara-test',
      description: 'Classica carbonara romana autentica test',
      ingredients: JSON.stringify([
        { nome: 'Spaghetti_test', quantita: '400g' },
        { nome: 'Guanciale_test', quantita: '150g' },
        { nome: 'Uova_test', quantita: '4' },
        { nome: 'Pecorino Romano_test', quantita: '100g' },
        { nome: 'Pepe nero_test', quantita: 'q.b.' }
      ]),
      instructions: JSON.stringify([
        { passo: 1, descrizione: 'Cuocere gli spaghetti in acqua salata_test' },
        { passo: 2, descrizione: 'Rosolare il guanciale a dadini_test' },
        { passo: 3, descrizione: 'Mescolare uova e pecorino_test' },
        { passo: 4, descrizione: 'Unire tutto e mantecare_test' }
      ]),
      prepTime: 10,
      cookTime: 15,
      servings: 4,
      difficulty: Difficulty.MEDIUM,
      authorId: normalUser.id,
      categoryId: categorieList.find(c => c.slug === 'primi-piatti-test')?.id,
      isPublic: true,
    }
  })

  const ricetta2 = await prisma.recipe.create({
    data: {
      title: 'Tiramisù_test',
      slug: 'tiramisu-test',
      description: 'Dolce italiano al caffè famoso in tutto il mondo test',
      ingredients: JSON.stringify([
        { nome: 'Savoiardi_test', quantita: '300g' },
        { nome: 'Mascarpone_test', quantita: '500g' },
        { nome: 'Uova_test', quantita: '4' },
        { nome: 'Zucchero_test', quantita: '100g' },
        { nome: 'Caffè_test', quantita: '300ml' },
        { nome: 'Cacao amaro_test', quantita: 'q.b.' }
      ]),
      instructions: JSON.stringify([
        { passo: 1, descrizione: 'Preparare il caffè e farlo raffreddare_test' },
        { passo: 2, descrizione: 'Montare tuorli e zucchero_test' },
        { passo: 3, descrizione: 'Aggiungere mascarpone_test' },
        { passo: 4, descrizione: 'Montare gli albumi_test' },
        { passo: 5, descrizione: 'Comporre a strati_test' }
      ]),
      prepTime: 30,
      cookTime: 0,
      servings: 8,
      difficulty: Difficulty.EASY,
      authorId: adminUser.id,
      categoryId: categorieList.find(c => c.slug === 'dolci-test')?.id,
      isPublic: true,
    }
  })

  console.log(`✅ Ricette create: ${ricetta1.title}, ${ricetta2.title}`)

  // 6. AGGIUNGI TAGS ALLE RICETTE
  const tagVeloce = tagsList.find(t => t.slug === 'veloce-test')
  const tagVegetariano = tagsList.find(t => t.slug === 'vegetariano-test')

  if (tagVeloce && ricetta1) {
    await prisma.recipeTag.create({
      data: {
        recipeId: ricetta1.id,
        tagId: tagVeloce.id
      }
    })
  }

  if (tagVegetariano && ricetta2) {
    await prisma.recipeTag.create({
      data: {
        recipeId: ricetta2.id,
        tagId: tagVegetariano.id
      }
    })
  }

  // 7. AGGIUNGI PREFERITI
  await prisma.favorite.create({
    data: {
      userId: normalUser.id,
      recipeId: ricetta2.id
    }
  })

  // 8. AGGIUNGI FOLLOW
  await prisma.follows.create({
    data: {
      followerId: normalUser.id,
      followingId: adminUser.id
    }
  })

  console.log('🎉 Seeding completato con successo!')
  console.log(`📊 Statistiche:`)
  console.log(`   👥 Utenti: 2`)
  console.log(`   🍝 Ricette: 2`)
  console.log(`   📁 Categorie: ${categorieList.length}`)
  console.log(`   🏷️ Tags: ${tagsList.length}`)
}

main()
  .catch((e) => {
    console.error('❌ Errore durante seeding:', e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
