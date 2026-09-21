import 'package:flutter/material.dart';

import '../../../../core/models/document_type_row.dart';

/// Admin adds a single index with an exact, hand-chosen value — e.g. to
/// carry over real numbers from an existing physical index register,
/// rather than the app's own generated TYPECODE-YEAR-NNNN shape.
class AddIndexDialog extends StatefulWidget {
  const AddIndexDialog({super.key, required this.types});

  final List<DocumentTypeRow> types;

  static Future<({int documentTypeId, String indexValue})?> show(BuildContext context, {required List<DocumentTypeRow> types}) {
    return showDialog(context: context, builder: (_) => AddIndexDialog(types: types));
  }

  @override
  State<AddIndexDialog> createState() => _AddIndexDialogState();
}

class _AddIndexDialogState extends State<AddIndexDialog> {
  int? _documentTypeId;
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.types.isNotEmpty) _documentTypeId = widget.types.first.id;
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add index'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _documentTypeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Document type'),
              items: [for (final t in widget.types) DropdownMenuItem(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _documentTypeId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valueController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Index value', hintText: 'e.g. PC-2026-0433'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final value = _valueController.text.trim();
            if (_documentTypeId == null || value.isEmpty) return;
            Navigator.of(context).pop((documentTypeId: _documentTypeId!, indexValue: value));
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
