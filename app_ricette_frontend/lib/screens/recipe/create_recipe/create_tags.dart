import 'package:flutter/material.dart';

class CreateTags extends StatefulWidget {
  final List<String> tags;
  final TextEditingController tagController;
  final Function() onAddTag;
  final Function(String) onRemoveTag;

  const CreateTags({
    super.key,
    required this.tags,
    required this.tagController,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  @override
  State<CreateTags> createState() => _CreateTagsState();
}

class _CreateTagsState extends State<CreateTags> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tag',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aggiungi tag per rendere la tua ricetta più facile da trovare',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.tagController,
                    decoration: const InputDecoration(
                      labelText: 'Nuovo tag',
                      border: OutlineInputBorder(),
                      hintText: 'es. vegano, veloce, estate...',
                    ),
                    onSubmitted: (_) => widget.onAddTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: widget.onAddTag,
                  tooltip: 'Aggiungi tag',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => widget.onRemoveTag(tag),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
