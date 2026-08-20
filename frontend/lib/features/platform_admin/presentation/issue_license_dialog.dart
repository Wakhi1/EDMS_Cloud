import 'package:flutter/material.dart';

const kLicenseTypes = <String>['trial', 'standard', 'enterprise'];

/// Pure picker — caller (company_detail_screen.dart) issues the license.
class IssueLicenseDialog extends StatefulWidget {
  const IssueLicenseDialog({super.key});

  @override
  State<IssueLicenseDialog> createState() => _IssueLicenseDialogState();
}

class _IssueLicenseDialogState extends State<IssueLicenseDialog> {
  String _licenseType = 'trial';
  DateTime _expiresAt = DateTime.now().add(const Duration(days: 30));
  final _maxUsersController = TextEditingController();
  final _storageQuotaGbController = TextEditingController();

  @override
  void dispose() {
    _maxUsersController.dispose();
    _storageQuotaGbController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Issue license'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Supersedes this company\'s current active license, if any.', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _licenseType,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'License type'),
              items: [for (final t in kLicenseTypes) DropdownMenuItem(value: t, child: Text(t))],
              onChanged: (v) => setState(() => _licenseType = v ?? _licenseType),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickExpiry,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Expires'),
                child: Text('${_expiresAt.year}-${_expiresAt.month.toString().padLeft(2, '0')}-${_expiresAt.day.toString().padLeft(2, '0')}'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxUsersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max users (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _storageQuotaGbController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Storage quota, GB (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final maxUsers = int.tryParse(_maxUsersController.text.trim());
            final storageGb = int.tryParse(_storageQuotaGbController.text.trim());
            Navigator.of(context).pop((
              licenseType: _licenseType,
              expiresAt: _expiresAt,
              maxUsers: maxUsers,
              storageQuotaBytes: storageGb == null ? null : storageGb * 1024 * 1024 * 1024,
            ));
          },
          child: const Text('Issue'),
        ),
      ],
    );
  }
}
