import 'package:flutter/material.dart';
import 'package:orsocook/models/recipe.dart';

class DetailHeaderSection extends StatelessWidget {
  final Recipe recipe;

  const DetailHeaderSection({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titolo
        Text(
          recipe.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Autore e categoria
        Row(
          children: [
            const Icon(Icons.person, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              recipe.author['username'] ?? 'Autore sconosciuto',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.category, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              recipe.category['name'] ?? 'Categoria',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Descrizione (se presente)
        if (recipe.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              recipe.description,
              style: const TextStyle(fontSize: 16),
            ),
          ),
      ],
    );
  }
}
