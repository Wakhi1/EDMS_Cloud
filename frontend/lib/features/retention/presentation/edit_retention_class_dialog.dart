import 'package:flutter/material.dart';

import '../../../core/models/retention_class_row.dart';

const _kDisposalActions = <String>['destroy', 'archive', 'transfer_to_national_archives', 'review'];

/// Edits a retention class's name/retention years/disposal action. Returns
/// the edited values on save, or null if cancelled — the actual PUT call
/// happens in the caller (retention_screen.dart), mirroring
/// RouteForApprovalDialog's "pure picker/editor, caller mutates" pattern.
/// A dedicated dialog (not ConfirmDialog) since three distinct fields don't
/// fit ConfirmDialog's single free-text-field shape.
class EditRetentionClassDialog extends StatefulWidget {
  const EditRetentionClassDialog({super.key, required this.retentionClass});

  final RetentionClassRow retentionClass;

  @override
  State<EditRetentionClassDialog> createState() => _EditRetentionClassDialogState();
}

class _EditRetentionClassDialogState extends State<EditRetentionClassDialog> {
  late final _nameController = TextEditingController(text: widget.retentionClass.name);
  late final _yearsController = TextEditingController(text: '${widget.retentionClass.retentionYears}');
  late String _disposalAction = widget.retentionClass.disposalAction;

  @override
  void dispose() {
    _nameController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.retentionClass.code}'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(
              controller: _yearsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Retention (years)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _disposalAction,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Disposal action'),
              items: [
                for (final a in _kDisposalActions) DropdownMenuItem(value: a, child: Text(a.replaceAll('_', ' '))),
              ],
              onChanged: (v) => setState(() => _disposalAction = v ?? _disposalAction),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final years = int.tryParse(_yearsController.text);
            Navigator.of(context).pop((
              name: _nameController.text,
              retentionYears: years,
              disposalAction: _disposalAction,
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
