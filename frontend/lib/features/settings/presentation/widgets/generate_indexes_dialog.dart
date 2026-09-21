import 'package:flutter/material.dart';

import '../../../../core/models/document_type_row.dart';

/// Admin bulk-generates N fresh available record_indexes rows for one
/// document type — see backend/routes/record-indexes.routes.js's
/// POST /generate.
class GenerateIndexesDialog extends StatefulWidget {
  const GenerateIndexesDialog({super.key, required this.types});

  final List<DocumentTypeRow> types;

  static Future<({int documentTypeId, int count})?> show(BuildContext context, {required List<DocumentTypeRow> types}) {
    return showDialog(context: context, builder: (_) => GenerateIndexesDialog(types: types));
  }

  @override
  State<GenerateIndexesDialog> createState() => _GenerateIndexesDialogState();
}

class _GenerateIndexesDialogState extends State<GenerateIndexesDialog> {
  int? _documentTypeId;
  final _countController = TextEditingController(text: '20');

  @override
  void initState() {
    super.initState();
    if (widget.types.isNotEmpty) _documentTypeId = widget.types.first.id;
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate indexes'),
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
              controller: _countController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'How many', hintText: '1-500'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final count = int.tryParse(_countController.text.trim());
            if (_documentTypeId == null || count == null || count < 1 || count > 500) return;
            Navigator.of(context).pop((documentTypeId: _documentTypeId!, count: count));
          },
          child: const Text('Generate'),
        ),
      ],
    );
  }
}
