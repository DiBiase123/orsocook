import 'package:flutter/material.dart';

class EditTags extends StatefulWidget {
  final List<dynamic> tags;
  final TextEditingController tagController;
  final Function() onAddTag;
  final Function(String) onRemoveTag;
  final Function(dynamic) extractTagName;
  final Function(dynamic) extractTagId;

  const EditTags({
    super.key,
    required this.tags,
    required this.tagController,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.extractTagName,
    required this.extractTagId,
  });

  @override
  State<EditTags> createState() => _EditTagsState();
}

class _EditTagsState extends State<EditTags> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tag',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    ),
                    onSubmitted: (_) => widget.onAddTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.green),
                  onPressed: widget.onAddTag,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.tags.map((tag) {
                  final tagName = widget.extractTagName(tag);
                  final tagId = widget.extractTagId(tag);
                  return Chip(
                    label: Text('$tagName${tagId != null ? ' ✓' : ' (nuovo)'}'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => widget.onRemoveTag(tagName),
                    backgroundColor:
                        tagId != null ? Colors.green[50] : Colors.orange[50],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
