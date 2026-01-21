import 'package:flutter/material.dart';

class CreateBasicInfo extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController prepTimeController;
  final TextEditingController cookTimeController;
  final TextEditingController servingsController;
  final String difficulty;
  final String category;
  final bool isPublic;
  final Function(String) onDifficultyChanged;
  final Function(String) onCategoryChanged;
  final Function(bool) onIsPublicChanged;

  const CreateBasicInfo({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.prepTimeController,
    required this.cookTimeController,
    required this.servingsController,
    required this.difficulty,
    required this.category,
    required this.isPublic,
    required this.onDifficultyChanged,
    required this.onCategoryChanged,
    required this.onIsPublicChanged,
  });

  @override
  State<CreateBasicInfo> createState() => _CreateBasicInfoState();
}

class _CreateBasicInfoState extends State<CreateBasicInfo> {
  // VALIDATORI INTERNI AL COMPONENTE
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName è obbligatorio';
    }
    return null;
  }

  String? _validateTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Il tempo è obbligatorio';
    }
    final time = int.tryParse(value);
    if (time == null || time <= 0) {
      return 'Inserisci un numero valido';
    }
    if (time > 600) {
      return 'Tempo troppo lungo (max 600 min)';
    }
    return null;
  }

  String? _validateServings(String? value) {
    if (value == null || value.isEmpty) {
      return 'Il numero di porzioni è obbligatorio';
    }
    final servings = int.tryParse(value);
    if (servings == null || servings <= 0) {
      return 'Inserisci un numero valido';
    }
    if (servings > 50) {
      return 'Numero di porzioni troppo alto';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informazioni Base',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.titleController,
              decoration: const InputDecoration(
                labelText: 'Titolo della ricetta *',
                border: OutlineInputBorder(),
                hintText: 'es. Spaghetti alla Carbonara',
              ),
              validator: (value) => _validateRequired(value, 'Il titolo'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrizione',
                border: OutlineInputBorder(),
                hintText: 'Descrivi brevemente la tua ricetta...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.prepTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Preparazione (min) *',
                      border: OutlineInputBorder(),
                      suffixText: 'min',
                    ),
                    validator: _validateTime,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: widget.cookTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cottura (min) *',
                      border: OutlineInputBorder(),
                      suffixText: 'min',
                    ),
                    validator: _validateTime,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: widget.servingsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Porzioni *',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateServings,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: widget.difficulty, // CORRETTO
                    decoration: const InputDecoration(
                      labelText: 'Difficoltà',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'EASY',
                        child: Text('Facile'),
                      ),
                      DropdownMenuItem(
                        value: 'MEDIUM',
                        child: Text('Media'),
                      ),
                      DropdownMenuItem(
                        value: 'HARD',
                        child: Text('Difficile'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        widget.onDifficultyChanged(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: widget.category, // CORRETTO
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      'Antipasti',
                      'Primi',
                      'Secondi',
                      'Contorni',
                      'Dolci',
                      'Bevande',
                    ].map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        widget.onCategoryChanged(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Ricetta pubblica'),
              subtitle: const Text('Visibile a tutti gli utenti'),
              value: widget.isPublic,
              onChanged: widget.onIsPublicChanged,
            ),
          ],
        ),
      ),
    );
  }
}
