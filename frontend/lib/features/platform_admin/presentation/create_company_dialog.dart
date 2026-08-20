import 'package:flutter/material.dart';

/// Pure picker/editor — caller (companies_list_screen.dart) makes the
/// actual API call, same "pure picker, caller mutates" shape used
/// throughout this app (e.g. features/permissions/presentation/grant_access_dialog.dart).
class CreateCompanyDialog extends StatefulWidget {
  const CreateCompanyDialog({super.key});

  @override
  State<CreateCompanyDialog> createState() => _CreateCompanyDialogState();
}

class _CreateCompanyDialogState extends State<CreateCompanyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _regController = TextEditingController();
  final _taxController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _regController.dispose();
    _taxController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      companyCode: _codeController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      registrationNo: _regController.text.trim().isEmpty ? null : _regController.text.trim(),
      taxId: _taxController.text.trim().isEmpty ? null : _taxController.text.trim(),
      contactName: _contactNameController.text.trim().isEmpty ? null : _contactNameController.text.trim(),
      contactEmail: _contactEmailController.text.trim().isEmpty ? null : _contactEmailController.text.trim(),
      contactPhone: _contactPhoneController.text.trim().isEmpty ? null : _contactPhoneController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New company'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Company code', hintText: 'e.g. ACME — used at login'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Company name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(controller: _regController, decoration: const InputDecoration(labelText: 'Registration number (optional)')),
                const SizedBox(height: 10),
                TextFormField(controller: _taxController, decoration: const InputDecoration(labelText: 'Tax ID (optional)')),
                const SizedBox(height: 10),
                TextFormField(controller: _contactNameController, decoration: const InputDecoration(labelText: 'Contact person (optional)')),
                const SizedBox(height: 10),
                TextFormField(controller: _contactEmailController, decoration: const InputDecoration(labelText: 'Contact email (optional)')),
                const SizedBox(height: 10),
                TextFormField(controller: _contactPhoneController, decoration: const InputDecoration(labelText: 'Contact phone (optional)')),
              ],
            ),
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
