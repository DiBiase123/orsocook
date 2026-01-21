import 'package:flutter/material.dart';
import 'package:orsocook/models/recipe.dart';

class DetailIngredientsSection extends StatelessWidget {
  final Recipe recipe;

  const DetailIngredientsSection({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titolo sezione
        const Text(
          'Ingredienti',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Lista ingredienti
        ...recipe.ingredients.map((ingredient) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 8),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${ingredient['quantity']} ${ingredient['unit']} ${ingredient['name']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
