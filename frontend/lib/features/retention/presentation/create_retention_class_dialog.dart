import 'package:flutter/material.dart';

const _kDisposalActions = <String>['destroy', 'archive', 'transfer_to_national_archives', 'review'];

/// Pure editor, caller mutates (same shape as EditRetentionClassDialog).
class CreateRetentionClassDialog extends StatefulWidget {
  const CreateRetentionClassDialog({super.key});

  @override
  State<CreateRetentionClassDialog> createState() => _CreateRetentionClassDialogState();
}

class _CreateRetentionClassDialogState extends State<CreateRetentionClassDialog> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _yearsController = TextEditingController(text: '7');
  String _disposalAction = 'review';

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New retention schedule'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _codeController, autofocus: true, decoration: const InputDecoration(labelText: 'Code (e.g. RC-CUSTOM-5)')),
            const SizedBox(height: 12),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: _yearsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Retention (years)')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _disposalAction,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Disposal action'),
              items: [for (final a in _kDisposalActions) DropdownMenuItem(value: a, child: Text(a.replaceAll('_', ' ')))],
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
            if (_codeController.text.trim().isEmpty || _nameController.text.trim().isEmpty || years == null) return;
            Navigator.of(context).pop((
              code: _codeController.text.trim(),
              name: _nameController.text.trim(),
              retentionYears: years,
              disposalAction: _disposalAction,
            ));
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
