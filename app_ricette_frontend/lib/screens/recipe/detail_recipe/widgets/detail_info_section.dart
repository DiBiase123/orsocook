import 'package:flutter/material.dart';
import 'package:orsocook/models/recipe.dart';

class DetailInfoSection extends StatelessWidget {
  final Recipe recipe;

  const DetailInfoSection({super.key, required this.recipe});

  // Helper per creare un'icona con testo
  Widget _buildInfoItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tempo totale (preparazione + cottura)
            _buildInfoItem(
                Icons.timer, '${recipe.prepTime + recipe.cookTime} min'),

            // Numero di persone
            _buildInfoItem(Icons.people, '${recipe.servings} pers.'),

            // Difficoltà
            _buildInfoItem(Icons.bar_chart, recipe.difficulty),

            // Visualizzazioni
            _buildInfoItem(Icons.visibility, '${recipe.views} visual.'),
          ],
        ),
      ),
    );
  }
}
