import 'package:flutter/material.dart';

/// Pure editor, caller mutates. Doubles as the edit dialog when
/// [initialLabel]/[initialText] are supplied — same fields, just
/// pre-filled and relabelled, rather than a near-duplicate dialog.
class AddWatermarkTemplateDialog extends StatefulWidget {
  const AddWatermarkTemplateDialog({super.key, this.initialLabel, this.initialText});

  final String? initialLabel;
  final String? initialText;

  bool get isEditing => initialLabel != null;

  @override
  State<AddWatermarkTemplateDialog> createState() => _AddWatermarkTemplateDialogState();
}

class _AddWatermarkTemplateDialogState extends State<AddWatermarkTemplateDialog> {
  late final _labelController = TextEditingController(text: widget.initialLabel ?? '');
  late final _textController = TextEditingController(text: widget.initialText ?? '');

  @override
  void dispose() {
    _labelController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit watermark template' : 'New watermark template'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _labelController, autofocus: true, decoration: const InputDecoration(labelText: 'Label', hintText: 'e.g. Confidential')),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(labelText: 'Watermark text', hintText: 'e.g. CONFIDENTIAL — PSPF INTERNAL USE ONLY'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_labelController.text.trim().isEmpty || _textController.text.trim().isEmpty) return;
            Navigator.of(context).pop((label: _labelController.text.trim(), text: _textController.text.trim()));
          },
          child: Text(widget.isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
