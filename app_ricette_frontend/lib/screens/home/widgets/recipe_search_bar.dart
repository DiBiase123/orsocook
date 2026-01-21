import 'package:flutter/material.dart';
import '../../../utils/logger.dart';

class RecipeSearchBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;

  const RecipeSearchBar({
    super.key,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🔍 Building RecipeSearchBar');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Cerca ricette, ingredienti...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }
}
