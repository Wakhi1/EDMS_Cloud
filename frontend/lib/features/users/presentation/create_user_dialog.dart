import 'package:flutter/material.dart';

import '../../../core/auth/known_roles.dart';
import '../../../core/models/department_row.dart';

/// Pure editor, caller mutates (same shape as CreateIntegrationDialog).
class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key, required this.departments});

  final List<DepartmentRow> departments;

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  int _roleId = kDefaultRoleId;
  int? _departmentId;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New user'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _fullNameController, autofocus: true, decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 12),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Temporary password (min. 10 characters)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _roleId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Role'),
                items: [for (final r in kKnownRoles) DropdownMenuItem(value: r.id, child: Text(r.name))],
                onChanged: (v) => setState(() => _roleId = v ?? _roleId),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _departmentId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Department (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  for (final d in widget.departments) DropdownMenuItem(value: d.id, child: Text(d.name)),
                ],
                onChanged: (v) => setState(() => _departmentId = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_fullNameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _passwordController.text.length < 10) return;
            Navigator.of(context).pop((
              fullName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              roleId: _roleId,
              departmentId: _departmentId,
            ));
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
