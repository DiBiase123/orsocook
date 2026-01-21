// lib/widgets/recipe_card.dart
// VERSIONE ADATTATA PER GRID 3 COLONNE

import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../utils/logger.dart';
import '../screens/recipe/widgets/favorite_button.dart';
import '../screens/recipe/widgets/like_button.dart';

@immutable
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final bool showAuthor;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.showAuthor = false, // 👈 DISATTIVATO DI DEFAULT PER GRID COMPATTO
  });

  void _handleTap() {
    AppLogger.navigation('🎯 Tap su RecipeCard: ${recipe.title}');
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🃏 Building RecipeCard: ${recipe.title}');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMMAGINE DELLA RICETTA CON BOTTONI
            if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
              _buildRecipeImage()
            else
              _buildPlaceholderImage(),

            Padding(
              padding: const EdgeInsets.all(12.0), // 👈 RIDOTTO DA 16 A 12
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titolo
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 16, // 👈 RIDOTTO DA 18 A 16
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6), // 👈 RIDOTTO DA 8 A 6

                  // Descrizione
                  if (recipe.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        recipe.description,
                        style: const TextStyle(
                          fontSize: 13, // 👈 RIDOTTO DA 14 A 13
                          color: Colors.grey,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Info (tempo e porzioni)
                  _buildRecipeInfo(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // INFO RICETTA COMPATTE
  Widget _buildRecipeInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tempo di preparazione
        Row(
          children: [
            const Icon(Icons.timer, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${recipe.totalTime}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Porzioni
        Row(
          children: [
            const Icon(Icons.restaurant, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${recipe.servings}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecipeImage() {
    return Stack(
      children: [
        // IMMAGINE DELLA RICETTA
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: SizedBox(
            height: 120, // 👈 RIDOTTO DA 150 A 120 (1/3 della card)
            width: double.infinity,
            child: Image.network(
              recipe.imageUrl!,
              headers: {'Accept': 'image/*'},
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  AppLogger.debug(
                      '✅ Image loaded successfully: ${recipe.imageUrl}');
                  return child;
                }
                AppLogger.debug('🔄 Loading image: ${recipe.imageUrl}');
                return Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                AppLogger.debug('❌ ERROR loading image: ${recipe.imageUrl}');
                return Container(
                  color: Colors.red[100],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error,
                            color: Colors.red, size: 30), // 👈 RIDOTTO
                        SizedBox(height: 4),
                        Text('Image error',
                            style: TextStyle(
                                color: Colors.red, fontSize: 10)), // 👈 RIDOTTO
                      ],
                    ),
                  ),
                );
              },
              fit: BoxFit.cover,
            ),
          ),
        ),

        // BOTTONI MI PIACE E PREFERITI
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              // BOTTONE MI PIACE
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(16), // 👈 RIDOTTO DA 20
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 3, // 👈 RIDOTTO DA 4
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                margin: const EdgeInsets.only(right: 4), // 👈 RIDOTTO DA 6
                child: LikeButton(
                  recipeId: recipe.id,
                  size: 18, // 👈 RIDOTTO DA 20
                ),
              ),

              // BOTTONE PREFERITI
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(16), // 👈 RIDOTTO DA 20
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 3, // 👈 RIDOTTO DA 4
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: FavoriteButton(
                  recipeId: recipe.id,
                  recipe: recipe,
                  size: 18, // 👈 RIDOTTO DA 20
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Stack(
      children: [
        // PLACEHOLDER IMMAGINE
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Container(
            height: 120, // 👈 RIDOTTO DA 150 A 120
            width: double.infinity,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(
                Icons.restaurant,
                size: 40, // 👈 RIDOTTO DA 60
                color: Colors.grey,
              ),
            ),
          ),
        ),

        // BOTTONI ANCHE SU PLACEHOLDER
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(16), // 👈 RIDOTTO
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 3, // 👈 RIDOTTO
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                margin: const EdgeInsets.only(right: 4), // 👈 RIDOTTO
                child: LikeButton(
                  recipeId: recipe.id,
                  size: 18, // 👈 RIDOTTO
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(16), // 👈 RIDOTTO
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 3, // 👈 RIDOTTO
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: FavoriteButton(
                  recipeId: recipe.id,
                  recipe: recipe,
                  size: 18, // 👈 RIDOTTO
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
