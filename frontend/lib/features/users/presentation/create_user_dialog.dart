import 'package:flutter/material.dart';

import '../../../core/models/department_row.dart';
import '../../../core/models/role_row.dart';

/// Pure editor, caller mutates (same shape as CreateIntegrationDialog).
class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key, required this.departments, required this.roles});

  final List<DepartmentRow> departments;
  final List<RoleRow> roles;

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late int? _roleId = widget.roles.firstOrNull?.id;
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
              DropdownButtonFormField<int?>(
                initialValue: _roleId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Role'),
                items: [for (final r in widget.roles) DropdownMenuItem(value: r.id, child: Text(r.name))],
                onChanged: (v) => setState(() => _roleId = v),
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
            final roleId = _roleId;
            if (_fullNameController.text.trim().isEmpty ||
                _emailController.text.trim().isEmpty ||
                _passwordController.text.length < 10 ||
                roleId == null) {
              return;
            }
            Navigator.of(context).pop((
              fullName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              roleId: roleId,
              departmentId: _departmentId,
            ));
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
