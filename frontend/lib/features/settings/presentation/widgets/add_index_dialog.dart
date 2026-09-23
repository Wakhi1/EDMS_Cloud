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
  // No type is pre-selected: silently defaulting to the first type is how
  // numbers ended up filed under the wrong type and never offered on upload.
  int? _documentTypeId;
  bool _typeChosenByUser = false;
  bool _showErrors = false;
  final _valueController = TextEditingController();

  /// Picks the type whose code the value starts with (e.g. "PV-2026-0042" → PV),
  /// until the user chooses a type themselves.
  void _onValueChanged(String value) {
    if (_typeChosenByUser) return;
    final prefix = RegExp(r'^[A-Za-z]+').stringMatch(value.trim())?.toUpperCase();
    final match = prefix == null ? null : widget.types.where((t) => t.code.toUpperCase() == prefix).firstOrNull;
    setState(() => _documentTypeId = match?.id);
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add record number'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _valueController,
              autofocus: true,
              onChanged: _onValueChanged,
              decoration: InputDecoration(
                labelText: 'Record number',
                hintText: 'e.g. PC-2026-0433',
                errorText: _showErrors && _valueController.text.trim().isEmpty ? 'Enter the number' : null,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey(_documentTypeId),
              initialValue: _documentTypeId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Document type',
                helperText: 'Uploads of this type will offer this number',
                errorText: _showErrors && _documentTypeId == null ? 'Choose the type this number belongs to' : null,
              ),
              items: [for (final t in widget.types) DropdownMenuItem(value: t.id, child: Text('${t.name}  (${t.code})', overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() {
                _documentTypeId = v;
                _typeChosenByUser = true;
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final value = _valueController.text.trim();
            if (_documentTypeId == null || value.isEmpty) {
              setState(() => _showErrors = true);
              return;
            }
            Navigator.of(context).pop((documentTypeId: _documentTypeId!, indexValue: value));
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
