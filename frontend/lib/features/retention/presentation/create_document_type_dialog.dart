import 'package:flutter/material.dart';

/// Pure editor, caller mutates. Doubles as the edit dialog when
/// [initialName]/[initialCode] are supplied — same fields, just pre-filled
/// and relabelled, rather than a near-duplicate dialog for editing an
/// existing document type.
class CreateDocumentTypeDialog extends StatefulWidget {
  const CreateDocumentTypeDialog({super.key, this.initialName, this.initialCode});

  final String? initialName;
  final String? initialCode;

  bool get isEditing => initialName != null;

  @override
  State<CreateDocumentTypeDialog> createState() => _CreateDocumentTypeDialogState();
}

class _CreateDocumentTypeDialogState extends State<CreateDocumentTypeDialog> {
  late final _nameController = TextEditingController(text: widget.initialName ?? '');
  late final _codeController = TextEditingController(text: widget.initialCode ?? '');

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit document type' : 'New document type'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: _codeController, decoration: const InputDecoration(labelText: 'Code (e.g. PC)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty || _codeController.text.trim().isEmpty) return;
            Navigator.of(context).pop((name: _nameController.text.trim(), code: _codeController.text.trim()));
          },
          child: Text(widget.isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
