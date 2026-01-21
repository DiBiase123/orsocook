import 'package:flutter/material.dart';

class EditInstructions extends StatefulWidget {
  final List<dynamic> instructions;
  final TextEditingController instructionController;
  final Function() onAddInstruction;
  final Function(int) onRemoveInstruction;

  const EditInstructions({
    super.key,
    required this.instructions,
    required this.instructionController,
    required this.onAddInstruction,
    required this.onRemoveInstruction,
  });

  @override
  State<EditInstructions> createState() => _EditInstructionsState();
}

class _EditInstructionsState extends State<EditInstructions> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      labelText: 'Nuovo passo',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => widget.onAddInstruction(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.green),
                  onPressed: widget.onAddInstruction,
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
              ...widget.instructions
                  .map((instruction) => _buildInstructionItem(instruction)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(dynamic instruction) {
    // Estrai i valori direttamente
    String step = '1';
    String description = 'Istruzione';

    if (instruction is Map) {
      final instructionMap = instruction as Map<String, dynamic>;
      step = instructionMap['step']?.toString() ?? '1';
      description = instructionMap['description']?.toString() ?? 'Istruzione';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          child: Text(step),
        ),
        title: Text(description),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => widget.onRemoveInstruction(
            widget.instructions.indexOf(instruction),
          ),
        ),
      ),
    );
  }
}
