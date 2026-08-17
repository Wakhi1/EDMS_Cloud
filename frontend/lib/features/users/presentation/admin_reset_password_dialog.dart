import 'package:flutter/material.dart';

/// Pure editor, caller mutates (same shape as CreateUserDialog) — an
/// obscured-field dialog for the admin "set a new password for this user"
/// action, distinct from the self-service Settings > Profile flow which
/// requires the user's own current password.
class AdminResetPasswordDialog extends StatefulWidget {
  const AdminResetPasswordDialog({super.key, required this.userFullName});

  final String userFullName;

  @override
  State<AdminResetPasswordDialog> createState() => _AdminResetPasswordDialogState();
}

class _AdminResetPasswordDialogState extends State<AdminResetPasswordDialog> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reset password for ${widget.userFullName}'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This immediately replaces their password and signs them out of every active session. You are responsible for relaying the new password to them securely.',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password (min. 10 characters)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_passwordController.text.length < 10) return;
            Navigator.of(context).pop(_passwordController.text);
          },
          child: const Text('Reset password'),
        ),
      ],
    );
  }
}
