import 'package:flutter/material.dart';

class CreateInstructions extends StatefulWidget {
  final List<Map<String, dynamic>> instructions;
  final TextEditingController instructionController;
  final Function() onAddInstruction;
  final Function(int) onRemoveInstruction;

  const CreateInstructions({
    super.key,
    required this.instructions,
    required this.instructionController,
    required this.onAddInstruction,
    required this.onRemoveInstruction,
  });

  @override
  State<CreateInstructions> createState() => _CreateInstructionsState();
}

class _CreateInstructionsState extends State<CreateInstructions> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Procedimento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.instructionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descrizione passo',
                      border: OutlineInputBorder(),
                      hintText: 'Descrivi il passo...',
                    ),
                    onSubmitted: (_) => widget.onAddInstruction(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: widget.onAddInstruction,
                  tooltip: 'Aggiungi passo',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.instructions.isNotEmpty) ...[
              const Text(
                'Passi del procedimento:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...widget.instructions.map((instruction) {
                final index = widget.instructions.indexOf(instruction);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[50],
                      child: Text('${instruction['step']}'),
                    ),
                    title: Text(instruction['description']),
                    trailing: IconButton(
                      icon:
                          const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => widget.onRemoveInstruction(index),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                );
              })
            ],
          ],
        ),
      ),
    );
  }
}
