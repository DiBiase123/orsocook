import 'package:flutter/material.dart';

class EditIngredients extends StatefulWidget {
  final List<dynamic> ingredients;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final Function() onAddIngredient;
  final Function(int) onRemoveIngredient;

  const EditIngredients({
    super.key,
    required this.ingredients,
    required this.nameController,
    required this.quantityController,
    required this.unitController,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
  });

  @override
  State<EditIngredients> createState() => _EditIngredientsState();
}

class _EditIngredientsState extends State<EditIngredients> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingredienti',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    widget.nameController,
                    'Nuovo ingrediente',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    widget.quantityController,
                    'Qtà',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    widget.unitController,
                    'Unità',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.green),
                  onPressed: widget.onAddIngredient,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.ingredients.isNotEmpty) ...[
              const Text(
                'Lista ingredienti:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...widget.ingredients
                  .asMap()
                  .entries
                  .map((entry) => _buildIngredientItem(entry.key, entry.value)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (_) => widget.onAddIngredient(),
    );
  }

  Widget _buildIngredientItem(int index, dynamic ingredient) {
    // Estrai i valori direttamente qui - NO extractValue esterno
    String name = 'Ingrediente';
    String quantity = '';
    String unit = '';

    if (ingredient is Map) {
      final ingredientMap = ingredient as Map<String, dynamic>;
      name = ingredientMap['name']?.toString() ?? 'Ingrediente';
      quantity = ingredientMap['quantity']?.toString() ?? '';
      unit = ingredientMap['unit']?.toString() ?? '';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepOrange[50],
          child: Text('${index + 1}'),
        ),
        title: Text(name),
        subtitle: Text('$quantity $unit'.trim()),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => widget.onRemoveIngredient(index),
        ),
      ),
    );
  }
}
