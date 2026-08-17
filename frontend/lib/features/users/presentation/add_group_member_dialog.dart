import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/models/group_row.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../providers/users_providers.dart';

/// Picks a user to add to [group] and returns their id, or null if
/// cancelled — the actual `addGroupMember` call happens in the caller
/// (users_screen.dart), same "pure picker" shape as RouteForApprovalDialog.
class AddGroupMemberDialog extends ConsumerWidget {
  const AddGroupMemberDialog({super.key, required this.group});

  final GroupRow group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final usersAsync = ref.watch(usersListProvider);
    final memberIds = group.members.map((m) => m.id).toSet();

    return AlertDialog(
      title: Text('Add member to ${group.name}'),
      content: SizedBox(
        width: 380,
        child: usersAsync.when(
          loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.bad)),
          data: (users) {
            final candidates = users.where((u) => !memberIds.contains(u.id)).toList();
            if (candidates.isEmpty) {
              return const Text('Every user is already a member of this group.');
            }
            return SizedBox(
              height: 320,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final u in candidates)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(u.fullName),
                      subtitle: Text('${u.email} · ${u.roleName}', style: const TextStyle(fontSize: 12)),
                      onTap: () => Navigator.of(context).pop(u.id),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
      ],
    );
  }
}
