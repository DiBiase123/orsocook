// lib/screens/home/widgets/categories_bar.dart
import 'package:flutter/material.dart';
import '../../../utils/logger.dart';

class CategoriesBar extends StatelessWidget {
  final ValueChanged<String>? onCategorySelected;

  const CategoriesBar({
    super.key,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🏷️ Building CategoriesBar');

    final categories = [
      'Tutte',
      'Italiane',
      'Dolci',
      'Veloci',
      'Vegetariane',
      'Carne',
      'Pesce'
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 16 : 8,
              right: index == categories.length - 1 ? 16 : 0,
            ),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: index == 0,
              onSelected: (selected) {
                AppLogger.debug(
                    '🎯 Categoria selezionata: ${categories[index]}');
                onCategorySelected?.call(categories[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
