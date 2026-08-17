import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../users/providers/users_providers.dart';

const kPermissionLevels = <String>['view', 'comment', 'edit', 'approve', 'full_control'];

/// Grants a new ACL entry: principal type (user/group) + principal id +
/// permission level. Returns the chosen values on save, null on cancel —
/// the actual `grant()` call happens in the caller
/// (permissions_target_screen.dart), same "pure picker/editor, caller
/// mutates" shape as EditRetentionClassDialog.
class GrantAccessDialog extends ConsumerStatefulWidget {
  const GrantAccessDialog({super.key});

  @override
  ConsumerState<GrantAccessDialog> createState() => _GrantAccessDialogState();
}

class _GrantAccessDialogState extends ConsumerState<GrantAccessDialog> {
  String _principalType = 'user';
  int? _principalId;
  String _permissionLevel = 'view';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersListProvider);
    final groupsAsync = ref.watch(groupsListProvider);

    return AlertDialog(
      title: const Text('Grant access'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'user', label: Text('User')),
                ButtonSegment(value: 'group', label: Text('Group')),
              ],
              selected: {_principalType},
              onSelectionChanged: (s) => setState(() {
                _principalType = s.first;
                _principalId = null;
              }),
            ),
            const SizedBox(height: 12),
            if (_principalType == 'user')
              usersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (users) => DropdownButtonFormField<int>(
                  initialValue: _principalId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'User'),
                  items: [for (final u in users) DropdownMenuItem(value: u.id, child: Text(u.fullName, overflow: TextOverflow.ellipsis))],
                  onChanged: (v) => setState(() => _principalId = v),
                ),
              )
            else
              groupsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (groups) => DropdownButtonFormField<int>(
                  initialValue: _principalId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Group'),
                  items: [for (final g in groups) DropdownMenuItem(value: g.id, child: Text(g.name, overflow: TextOverflow.ellipsis))],
                  onChanged: (v) => setState(() => _principalId = v),
                ),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _permissionLevel,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Permission level'),
              items: [for (final l in kPermissionLevels) DropdownMenuItem(value: l, child: Text(l.replaceAll('_', ' ')))],
              onChanged: (v) => setState(() => _permissionLevel = v ?? _permissionLevel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _principalId == null
              ? null
              : () => Navigator.of(context).pop((
                    principalType: _principalType,
                    principalId: _principalId!,
                    permissionLevel: _permissionLevel,
                  )),
          child: const Text('Grant'),
        ),
      ],
    );
  }
}
