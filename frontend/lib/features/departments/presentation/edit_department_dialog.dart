import 'package:flutter/material.dart';

import '../../../core/models/department_row.dart';

/// Pure editor, caller mutates — same shape as EditIntegrationDialog.
class EditDepartmentDialog extends StatefulWidget {
  const EditDepartmentDialog({super.key, required this.department});

  final DepartmentRow department;

  @override
  State<EditDepartmentDialog> createState() => _EditDepartmentDialogState();
}

class _EditDepartmentDialogState extends State<EditDepartmentDialog> {
  late final _nameController = TextEditingController(text: widget.department.name);
  late final _descriptionController = TextEditingController(text: widget.department.description ?? '');
  late bool _isActive = widget.department.isActive;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.department.name}'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Active'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop((
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            isActive: _isActive,
          )),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
