import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/module_access.dart';
import '../../../core/models/access_request_row.dart';
import '../../../core/models/permission_matrix_cell.dart';
import '../../../core/models/role_row.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/result_dialog.dart';
import '../../users/providers/users_providers.dart';
import '../providers/permissions_providers.dart';
import 'create_role_dialog.dart';

class PermissionsHomeScreen extends ConsumerWidget {
  const PermissionsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matrixAsync = ref.watch(permissionMatrixProvider);
    final rolesAsync = ref.watch(rolesProvider);
    final roles = rolesAsync.valueOrNull ?? const <RoleRow>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Administration / Folder & Document Access', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 18),
          const _RolesSection(),
          const SizedBox(height: 24),
          const _AccessRequestsSection(),
          const SizedBox(height: 24),
          Text('ROLE × MODULE PERMISSION MATRIX', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          matrixAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
            error: (e, _) {
              if (e is ApiException && e.isForbidden) {
                return const EmptyState(message: 'The role × module permission matrix is visible to System Administrators only.');
              }
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text('$e', style: TextStyle(color: context.tokens.bad)),
              );
            },
            data: (cells) => _MatrixGrid(cells: cells, roles: roles),
          ),
          const SizedBox(height: 28),
          _TargetPickerHint(),
        ],
      ),
    );
  }
}

/// Roles list with +New/Edit/Delete — the matrix below it has one row per
/// role here, so creating a role and then granting it module access are two
/// steps on the same screen. Read-only for anyone without 'users' view
/// access; create/edit/delete additionally require System Administrator
/// server-side (see backend/routes/roles.routes.js) — a non-admin viewer
/// just won't see the action buttons succeed (403 surfaces as a snackbar).
class _RolesSection extends ConsumerWidget {
  const _RolesSection();

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String name, String? description, bool mfaRequired})>(
      context: context,
      builder: (_) => const CreateRoleDialog(),
    );
    if (result == null) return;

    try {
      await ref.read(rolesApiProvider).create(name: result.name, description: result.description, mfaRequired: result.mfaRequired);
      ref.invalidate(rolesProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role created.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, RoleRow row) async {
    final result = await showDialog<({String name, String? description, bool mfaRequired})>(
      context: context,
      builder: (_) => CreateRoleDialog(initialName: row.name, initialDescription: row.description, initialMfaRequired: row.mfaRequired),
    );
    if (result == null) return;

    try {
      await ref.read(rolesApiProvider).update(row.id, name: result.name, description: result.description, mfaRequired: result.mfaRequired);
      ref.invalidate(rolesProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role updated.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, RoleRow row) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete "${row.name}"?',
      body: 'Refused if any user or workflow step still uses this role.',
      okLabel: 'Delete',
      danger: true,
    );
    if (confirmed == null) return;

    try {
      await ref.read(rolesApiProvider).delete(row.id);
      ref.invalidate(rolesProvider);
      if (context.mounted) await ResultDialog.showSuccess(context, 'Role deleted.');
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final rolesAsync = ref.watch(rolesProvider);

    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Text('ROLES', style: textTheme.labelSmall),
                const Spacer(),
                TextButton(onPressed: () => _create(context, ref), child: const Text('+ New')),
              ],
            ),
          ),
          rolesAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.bad, fontSize: 12)),
            ),
            data: (rows) {
              if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(12), child: Text('No roles defined.'));
              return Column(
                children: [
                  for (final r in rows)
                    Container(
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
                                    Text(r.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    if (r.mfaRequired) ...[const SizedBox(width: 6), Text('MFA required', style: TextStyle(fontSize: 11, color: tokens.ink2))],
                                    if (r.isSystemRole) ...[const SizedBox(width: 6), Text('· built-in', style: TextStyle(fontSize: 11, color: tokens.ink2))],
                                  ],
                                ),
                                if (r.description != null) Text(r.description!, style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
                              ],
                            ),
                          ),
                          OutlinedButton(onPressed: () => _edit(context, ref, r), child: const Text('Edit')),
                          const SizedBox(width: 6),
                          OutlinedButton(
                            onPressed: r.isSystemRole ? null : () => _delete(context, ref, r),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Pending self-service access requests (see request_access_dialog.dart /
/// backend/routes/access-requests.routes.js). Query is [silent403] so a
/// non-approver landing on this shared screen doesn't get bounced just
/// because this one section is gated behind 'permissions' edit access.
class _AccessRequestsSection extends ConsumerWidget {
  const _AccessRequestsSection();

  Future<void> _approve(BuildContext context, WidgetRef ref, AccessRequestRow row) async {
    try {
      await ref.read(accessRequestsApiProvider).approve(row.id);
      ref.invalidate(accessRequestsQueueProvider);
      if (context.mounted) await ResultDialog.showSuccess(context, 'Access request approved.');
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  Future<void> _deny(BuildContext context, WidgetRef ref, AccessRequestRow row) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Deny ${row.requesterName ?? 'this user'}\'s request for ${row.requestedLevel.replaceAll('_', ' ')} access?',
      danger: true,
    );
    if (confirmed == null) return;

    try {
      await ref.read(accessRequestsApiProvider).deny(row.id);
      ref.invalidate(accessRequestsQueueProvider);
      if (context.mounted) await ResultDialog.showSuccess(context, 'Access request denied.');
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final queueAsync = ref.watch(accessRequestsQueueProvider);

    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text('PENDING ACCESS REQUESTS', style: textTheme.labelSmall),
          ),
          queueAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
            error: (e, _) {
              if (e is ApiException && e.isForbidden) {
                return const EmptyState(message: 'Access requests are visible to approvers only.');
              }
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.bad, fontSize: 12)),
              );
            },
            data: (rows) {
              if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(12), child: Text('No pending requests.'));
              return Column(
                children: [
                  for (final row in rows)
                    Container(
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
                                    Text(row.requesterName ?? '#${row.requesterId}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'wants ${row.requestedLevel.replaceAll('_', ' ')} on ${row.targetType} #${row.targetId}',
                                      style: TextStyle(fontSize: 11.5, color: tokens.ink2),
                                    ),
                                  ],
                                ),
                                if (row.reason != null && row.reason!.isNotEmpty)
                                  Text(row.reason!, style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
                              ],
                            ),
                          ),
                          OutlinedButton(onPressed: () => _approve(context, ref, row), child: const Text('Approve')),
                          const SizedBox(width: 6),
                          OutlinedButton(
                            onPressed: () => _deny(context, ref, row),
                            style: OutlinedButton.styleFrom(foregroundColor: tokens.bad, side: BorderSide(color: tokens.bad)),
                            child: const Text('Deny'),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TargetPickerHint extends StatelessWidget {
  const _TargetPickerHint();

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      message: 'Folder and document access lists are managed per-target. Open a folder in Repository or a record '
          'in the Viewer and choose "Manage access".',
      action: OutlinedButton(
        onPressed: () => context.go(RoutePaths.repository),
        child: const Text('Go to Repository'),
      ),
    );
  }
}

class _MatrixGrid extends StatelessWidget {
  const _MatrixGrid({required this.cells, required this.roles});

  final List<PermissionMatrixCell> cells;
  final List<RoleRow> roles;

  PermissionMatrixCell _cellFor(int roleId, String module) {
    return cells.firstWhere(
      (c) => c.roleId == roleId && c.module == module,
      orElse: () => PermissionMatrixCell(roleId: roleId, module: module, canView: false, canEdit: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // Every column needs an explicit width — inside a horizontally-scrolling
    // SingleChildScrollView the Table has unbounded width to flex against,
    // so any column without a FixedColumnWidth collapses toward zero and
    // its Text content wraps character-by-character instead of rendering.
    final columnWidths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(150),
      for (var i = 0; i < kPermissionModules.length; i++) i + 1: const FixedColumnWidth(120),
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: tokens.line),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: columnWidths,
        children: [
          TableRow(
            decoration: BoxDecoration(color: tokens.surf2),
            children: [
              const Padding(padding: EdgeInsets.all(8), child: Text('Role', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              for (final module in kPermissionModules)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(module, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12), softWrap: false, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
          for (final role in roles)
            TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(8), child: Text(role.name, style: const TextStyle(fontSize: 12.5))),
                for (final module in kPermissionModules)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _MatrixCell(cell: _cellFor(role.id, module)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MatrixCell extends ConsumerStatefulWidget {
  const _MatrixCell({required this.cell});

  final PermissionMatrixCell cell;

  @override
  ConsumerState<_MatrixCell> createState() => _MatrixCellState();
}

class _MatrixCellState extends ConsumerState<_MatrixCell> {
  bool _busy = false;

  Future<void> _toggle({required bool isView, required bool newValue}) async {
    final cell = widget.cell;
    final me = ref.read(currentUserProvider);
    final losingOwnPermissionsAccess = me?.roleId == cell.roleId && cell.module == 'permissions' && !newValue;

    if (losingOwnPermissionsAccess) {
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Remove your own ${isView ? "view" : "edit"} access to Permissions?',
        body: 'You are about to change the "permissions" module\'s ${isView ? "view" : "edit"} setting for your own role (${me!.role}).',
        note: isView
            ? 'Unchecking this will immediately lock you out of the folder/document access screen for every '
                'record. It does not lock you out of this matrix — you can restore it here at any time.'
            : 'Unchecking this will immediately stop you from granting or revoking access on any folder or '
                'document. It does not lock you out of this matrix — you can restore it here at any time.',
        okLabel: 'Remove my own access',
        danger: true,
      );
      if (confirmed == null) return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(permissionsApiProvider).updateMatrixCell(
            roleId: cell.roleId,
            module: cell.module,
            canView: isView ? newValue : cell.canView,
            canEdit: isView ? cell.canEdit : newValue,
          );
      ref.invalidate(permissionMatrixProvider);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cell = widget.cell;
    return Opacity(
      opacity: _busy ? 0.5 : 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'View',
            child: Checkbox(
              value: cell.canView,
              onChanged: _busy ? null : (v) => _toggle(isView: true, newValue: v ?? false),
            ),
          ),
          Tooltip(
            message: 'Edit',
            child: Checkbox(
              value: cell.canEdit,
              onChanged: _busy ? null : (v) => _toggle(isView: false, newValue: v ?? false),
            ),
          ),
        ],
      ),
    );
  }
}
