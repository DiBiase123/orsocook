-- Vedere tutte le ricette
SELECT id, title, description, "userId", "createdAt" 
FROM "Recipe" 
ORDER BY "createdAt" DESC 
LIMIT 10;

-- Contare le ricette
SELECT COUNT(*) as total_recipes FROM "Recipe";

-- Vedere se ci sono categorie
SELECT * FROM "Category" LIMIT 10;
