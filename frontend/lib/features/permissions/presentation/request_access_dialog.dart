import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'grant_access_dialog.dart' show kPermissionLevels;

/// Self-service "request access" for a user who can't see/edit a target.
/// Returns the chosen level + optional reason on submit, null on cancel —
/// the actual `create()` call happens in the caller
/// (permissions_target_screen.dart), same "pure picker/editor, caller
/// mutates" shape as [GrantAccessDialog].
class RequestAccessDialog extends ConsumerStatefulWidget {
  const RequestAccessDialog({super.key});

  @override
  ConsumerState<RequestAccessDialog> createState() => _RequestAccessDialogState();
}

class _RequestAccessDialogState extends ConsumerState<RequestAccessDialog> {
  String _requestedLevel = 'view';
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request access'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _requestedLevel,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Requested level'),
              items: [for (final l in kPermissionLevels) DropdownMenuItem(value: l, child: Text(l.replaceAll('_', ' ')))],
              onChanged: (v) => setState(() => _requestedLevel = v ?? _requestedLevel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Reason (optional)', alignLabelWithHint: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop((
            requestedLevel: _requestedLevel,
            reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
          )),
          child: const Text('Submit request'),
        ),
      ],
    );
  }
}
