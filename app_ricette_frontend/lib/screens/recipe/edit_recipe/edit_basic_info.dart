import 'package:flutter/material.dart';

class EditBasicInfo extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController prepTimeController;
  final TextEditingController cookTimeController;
  final TextEditingController servingsController;
  final String difficulty;
  final bool isPublic;
  final Function(String) onDifficultyChanged;
  final Function(bool) onIsPublicChanged;
  final Function(String?, String) validateRequired;
  final Function(String?, String) validateNumber;

  const EditBasicInfo({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.prepTimeController,
    required this.cookTimeController,
    required this.servingsController,
    required this.difficulty,
    required this.isPublic,
    required this.onDifficultyChanged,
    required this.onIsPublicChanged,
    required this.validateRequired,
    required this.validateNumber,
  });

  @override
  State<EditBasicInfo> createState() => _EditBasicInfoState();
}

class _EditBasicInfoState extends State<EditBasicInfo> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                labelText: 'Titolo *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => widget.validateRequired(value, 'Il titolo'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.descriptionController.text, // CORRETTO
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrizione',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                widget.descriptionController.text = value;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    widget.prepTimeController,
                    'Preparazione (min) *',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberField(
                    widget.cookTimeController,
                    'Cottura (min) *',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberField(
                    widget.servingsController,
                    'Porzioni *',
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
                  child: SwitchListTile(
                    title: const Text('Pubblica'),
                    subtitle: const Text('Visibile a tutti'),
                    value: widget.isPublic,
                    onChanged: widget.onIsPublicChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(
    TextEditingController controller,
    String label,
  ) {
    return TextFormField(
      initialValue: controller.text, // CORRETTO
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => widget.validateNumber(value, label.split(' ')[0]),
      onChanged: (value) {
        controller.text = value;
      },
    );
  }
}
