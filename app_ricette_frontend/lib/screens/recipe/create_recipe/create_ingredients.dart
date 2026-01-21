import 'package:flutter/material.dart';

class CreateIngredients extends StatefulWidget {
  final List<Map<String, dynamic>> ingredients;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final Function() onAddIngredient;
  final Function(int) onRemoveIngredient;

  const CreateIngredients({
    super.key,
    required this.ingredients,
    required this.nameController,
    required this.quantityController,
    required this.unitController,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
  });

  @override
  State<CreateIngredients> createState() => _CreateIngredientsState();
}

class _CreateIngredientsState extends State<CreateIngredients> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                  child: TextField(
                    controller: widget.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome ingrediente',
                      border: OutlineInputBorder(),
                      hintText: 'es. Farina',
                    ),
                    onSubmitted: (_) => widget.onAddIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: widget.quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Qtà',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => widget.onAddIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: widget.unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unità',
                      border: OutlineInputBorder(),
                      hintText: 'g, ml, etc.',
                    ),
                    onSubmitted: (_) => widget.onAddIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: widget.onAddIngredient,
                  tooltip: 'Aggiungi ingrediente',
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
              ...widget.ingredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepOrange[50],
                    child: Text('${index + 1}'),
                  ),
                  title: Text(ingredient['name']),
                  subtitle:
                      Text('${ingredient['quantity']} ${ingredient['unit']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => widget.onRemoveIngredient(index),
                  ),
                  dense: true,
                );
              })
            ],
          ],
        ),
      ),
    );
  }
}
