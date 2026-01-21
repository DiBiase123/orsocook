import 'package:flutter/material.dart';

class EditHeader extends StatelessWidget {
  final String recipeTitle;
  final String recipeId;
  final bool hasChanges;

  const EditHeader({
    super.key,
    required this.recipeTitle,
    required this.recipeId,
    required this.hasChanges,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text(
                  'Modifica: $recipeTitle',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ID: $recipeId',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (hasChanges) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Ci sono modifiche non salvate',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
