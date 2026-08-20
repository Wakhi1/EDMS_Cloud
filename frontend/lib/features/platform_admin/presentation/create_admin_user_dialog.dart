import 'package:flutter/material.dart';

/// Pure picker — bootstraps a company's first System Administrator user.
/// Caller (company_detail_screen.dart) makes the API call.
class CreateAdminUserDialog extends StatefulWidget {
  const CreateAdminUserDialog({super.key});

  @override
  State<CreateAdminUserDialog> createState() => _CreateAdminUserDialogState();
}

class _CreateAdminUserDialogState extends State<CreateAdminUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create admin user'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bootstraps this company\'s first System Administrator account.', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Temporary password'),
                obscureText: true,
                validator: (v) => (v == null || v.length < 10) ? 'At least 10 characters' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}
