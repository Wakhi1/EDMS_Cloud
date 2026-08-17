import 'package:flutter/material.dart';

const _kIntegrationStatuses = <String>['connected', 'disconnected', 'error'];

/// Registers a brand-new integration entry. Returns the entered values on
/// save, or null if cancelled — the actual POST call happens in the caller
/// (integrations_screen.dart), same "pure editor, caller mutates" shape as
/// EditIntegrationDialog.
class CreateIntegrationDialog extends StatefulWidget {
  const CreateIntegrationDialog({super.key});

  @override
  State<CreateIntegrationDialog> createState() => _CreateIntegrationDialogState();
}

class _CreateIntegrationDialogState extends State<CreateIntegrationDialog> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _endpointController = TextEditingController();
  String _status = 'disconnected';

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  void _save() {
    final id = _idController.text.trim();
    final name = _nameController.text.trim();
    if (id.isEmpty || name.isEmpty) return;
    Navigator.of(context).pop((
      id: id,
      name: name,
      description: _descriptionController.text.trim(),
      endpoint: _endpointController.text.trim(),
      status: _status,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add integration'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'ID',
                helperText: 'Lowercase, no spaces — the internal key',
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            TextField(controller: _endpointController, decoration: const InputDecoration(labelText: 'Endpoint')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [for (final s in _kIntegrationStatuses) DropdownMenuItem(value: s, child: Text(s))],
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Create')),
      ],
    );
  }
}
