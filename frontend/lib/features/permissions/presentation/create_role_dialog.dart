import 'package:flutter/material.dart';

/// Pure editor, caller mutates. Doubles as the edit dialog when
/// [initialName] is supplied — same fields, just pre-filled and relabelled,
/// rather than a near-duplicate dialog for editing an existing role.
class CreateRoleDialog extends StatefulWidget {
  const CreateRoleDialog({super.key, this.initialName, this.initialDescription, this.initialMfaRequired = false});

  final String? initialName;
  final String? initialDescription;
  final bool initialMfaRequired;

  bool get isEditing => initialName != null;

  @override
  State<CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends State<CreateRoleDialog> {
  late final _nameController = TextEditingController(text: widget.initialName ?? '');
  late final _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
  late bool _mfaRequired = widget.initialMfaRequired;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit role' : 'New role'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description (optional)')),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _mfaRequired,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Require MFA for this role'),
              onChanged: (v) => setState(() => _mfaRequired = v ?? false),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'New roles start with no module access — grant it in the permission matrix below after creating.',
                style: TextStyle(fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            Navigator.of(context).pop((
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
              mfaRequired: _mfaRequired,
            ));
          },
          child: Text(widget.isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
