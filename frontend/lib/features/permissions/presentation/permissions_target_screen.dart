import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/acl_entry_row.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/result_dialog.dart';
import '../../document_viewer/providers/viewer_providers.dart';
import '../../repository/providers/repository_providers.dart';
import '../providers/permissions_providers.dart';
import 'grant_access_dialog.dart';
import 'request_access_dialog.dart';

class PermissionsTargetScreen extends ConsumerWidget {
  const PermissionsTargetScreen({super.key, required this.targetType, required this.targetId});

  final String targetType;
  final String targetId;

  Future<void> _requestAccess(BuildContext context, WidgetRef ref, {required int id}) async {
    final result = await showDialog<({String requestedLevel, String? reason})>(
      context: context,
      builder: (_) => const RequestAccessDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(accessRequestsApiProvider).create(
            targetType: targetType,
            targetId: id,
            requestedLevel: result.requestedLevel,
            reason: result.reason,
          );
      if (context.mounted) {
        await ResultDialog.showSuccess(context, 'Access request submitted.');
      }
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (targetType != 'folder' && targetType != 'document') {
      return const EmptyState(message: 'Invalid access target.');
    }
    final id = int.tryParse(targetId);
    if (id == null) {
      return const EmptyState(message: 'Invalid access target.');
    }

    final tokens = context.tokens;
    final aclAsync = ref.watch(aclProvider((targetType, targetId)));
    final docAsync = targetType == 'document' ? ref.watch(documentDetailProvider(id)) : null;
    final foldersAsync = targetType == 'folder' ? ref.watch(foldersProvider) : null;
    final folderName = foldersAsync?.valueOrNull?.where((f) => f.id == id).firstOrNull?.path;
    final title = docAsync?.valueOrNull?.title ?? folderName ?? '${targetType[0].toUpperCase()}${targetType.substring(1)} #$targetId';

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Records / Access', style: Theme.of(context).textTheme.labelSmall),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Expanded(
            child: aclAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) {
                if (error is ApiException && error.isForbidden) {
                  // Someone without 'permissions' module access can't see the
                  // ACL — but self-service requesting is the whole point of
                  // this flow, so give them just the request button instead
                  // of bouncing to /access-denied (see aclProvider's silent403).
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("You don't have access to view this record's permissions.", style: TextStyle(color: tokens.ink2)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _requestAccess(context, ref, id: id),
                          child: const Text('Request access'),
                        ),
                      ],
                    ),
                  );
                }
                return ErrorState(
                  message: error is ApiException ? error.message : '$error',
                  onRetry: () => ref.invalidate(aclProvider((targetType, targetId))),
                );
              },
              data: (acl) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('OWN ACCESS', style: Theme.of(context).textTheme.labelSmall),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () => _requestAccess(context, ref, id: id),
                          child: const Text('Request access'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final result = await showDialog<({String principalType, int principalId, String permissionLevel})>(
                              context: context,
                              builder: (_) => const GrantAccessDialog(),
                            );
                            if (result == null) return;
                            try {
                              await ref.read(permissionsApiProvider).grant(
                                    targetType,
                                    targetId,
                                    principalType: result.principalType,
                                    principalId: result.principalId,
                                    permissionLevel: result.permissionLevel,
                                  );
                              ref.invalidate(aclProvider((targetType, targetId)));
                              if (context.mounted) {
                                await ResultDialog.showSuccess(context, 'Access granted.');
                              }
                            } on ApiException catch (e) {
                              if (context.mounted) await ResultDialog.showError(context, e.message);
                            }
                          },
                          child: const Text('Grant access'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (acl.own.isEmpty)
                      const EmptyState(message: 'No access grants on this record.')
                    else
                      for (final entry in acl.own) _AclRow(entry: entry, targetType: targetType, targetId: targetId, revocable: true),
                    if (targetType == 'document' && acl.inherited.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text('INHERITED FROM FOLDER', style: Theme.of(context).textTheme.labelSmall),
                      Text(
                        'Managed from the folder\'s own access screen — not revocable here.',
                        style: TextStyle(fontSize: 11.5, color: tokens.ink2),
                      ),
                      const SizedBox(height: 8),
                      for (final entry in acl.inherited) _AclRow(entry: entry, targetType: targetType, targetId: targetId, revocable: false),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AclRow extends ConsumerWidget {
  const _AclRow({required this.entry, required this.targetType, required this.targetId, required this.revocable});

  final AclEntryRow entry;
  final String targetType;
  final String targetId;
  final bool revocable;

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Revoke ${entry.permissionLevel.replaceAll('_', ' ')} from ${entry.principalName}?',
      danger: true,
    );
    if (confirmed == null) return;

    try {
      await ref.read(permissionsApiProvider).revoke(entry.id);
      ref.invalidate(aclProvider((targetType, targetId)));
      if (context.mounted) {
        await ResultDialog.showSuccess(context, 'Access revoked.');
      }
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.line))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.principalName ?? '#${entry.principalId}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text('(${entry.principalType})', style: TextStyle(fontSize: 11, color: tokens.ink2)),
                  ],
                ),
                Text(entry.permissionLevel.replaceAll('_', ' '), style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
              ],
            ),
          ),
          if (revocable)
            OutlinedButton(
              onPressed: () => _revoke(context, ref),
              style: OutlinedButton.styleFrom(foregroundColor: tokens.bad, side: BorderSide(color: tokens.bad)),
              child: const Text('Revoke'),
            ),
        ],
      ),
    );
  }
}
