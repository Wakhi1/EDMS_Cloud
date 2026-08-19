import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/group_row.dart';
import '../../../core/models/role_row.dart';
import '../../../core/models/user_row.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../../departments/providers/departments_providers.dart';
import '../providers/users_providers.dart';
import 'add_group_member_dialog.dart';
import 'admin_reset_password_dialog.dart';
import 'create_user_dialog.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The users table and the groups list can both grow without bound (more
    // staff, more groups) — rather than splitting a fixed viewport height
    // between two independently-growing lists (which is what caused the
    // bottom overflow: neither list is scrollable on its own, and this
    // screen must work across web, desktop, and narrow/tablet windows),
    // the whole page scrolls as one column instead.
    return const Padding(
      padding: EdgeInsets.all(18),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UsersSection(),
            SizedBox(height: 24),
            _GroupsSection(),
          ],
        ),
      ),
    );
  }
}

class _UsersSection extends ConsumerWidget {
  const _UsersSection();

  Future<void> _createUser(BuildContext context, WidgetRef ref) async {
    final departments = await ref.read(departmentsListProvider.future);
    final roles = await ref.read(rolesProvider.future);
    if (!context.mounted) return;
    final result = await showDialog<({String fullName, String email, String password, int roleId, int? departmentId})>(
      context: context,
      builder: (_) => CreateUserDialog(departments: departments, roles: roles),
    );
    if (result == null) return;

    try {
      await ref.read(usersApiProvider).create(
            fullName: result.fullName,
            email: result.email,
            password: result.password,
            roleId: result.roleId,
            departmentId: result.departmentId,
          );
      ref.invalidate(usersListProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deactivate(BuildContext context, WidgetRef ref, UserRow row) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Deactivate ${row.fullName}?',
      body: 'This immediately prevents further sign-ins. The account is never hard-deleted (existing records/audit history keep referencing it).',
      okLabel: 'Deactivate',
      danger: true,
    );
    if (confirmed == null) return;

    try {
      await ref.read(usersApiProvider).deactivate(row.id);
      ref.invalidate(usersListProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deactivated.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _changeRole(BuildContext context, WidgetRef ref, UserRow row, RoleRow newRole) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: "Change ${row.fullName}'s role to ${newRole.name}?",
      rows: [('Current role', row.roleName), ('New role', newRole.name)],
      okLabel: 'Change role',
    );
    if (confirmed == null) return;

    try {
      await ref.read(usersApiProvider).updateRole(row.id, newRole.id);
      ref.invalidate(usersListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role updated.')));
      }
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _toggleLock(BuildContext context, WidgetRef ref, UserRow row) async {
    final locking = !row.isLocked;
    final confirmed = await ConfirmDialog.show(
      context,
      title: '${locking ? "Lock" : "Unlock"} ${row.fullName}?',
      body: locking ? 'This immediately signs the account out and prevents further sign-ins.' : null,
      okLabel: locking ? 'Lock account' : 'Unlock account',
      danger: locking,
    );
    if (confirmed == null) return;

    try {
      await ref.read(usersApiProvider).updateLock(row.id, locking);
      ref.invalidate(usersListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locking ? 'Account locked.' : 'Account unlocked.')));
      }
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _changeDepartment(BuildContext context, WidgetRef ref, UserRow row, int? newDepartmentId, String? newDepartmentName) async {
    if (newDepartmentId == row.departmentId) return;
    final confirmed = await ConfirmDialog.show(
      context,
      title: "Move ${row.fullName} to ${newDepartmentName ?? 'Unassigned'}?",
      rows: [('Current department', row.departmentName ?? 'Unassigned'), ('New department', newDepartmentName ?? 'Unassigned')],
      okLabel: 'Change department',
    );
    if (confirmed == null) return;

    try {
      await ref.read(usersApiProvider).updateDepartment(row.id, newDepartmentId);
      ref.invalidate(usersListProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department updated.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref, UserRow row) async {
    final newPassword = await showDialog<String>(context: context, builder: (_) => AdminResetPasswordDialog(userFullName: row.fullName));
    if (newPassword == null) return;

    try {
      await ref.read(usersApiProvider).resetPassword(row.id, newPassword);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset. Relay it to the user securely.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _toggleMfa(BuildContext context, WidgetRef ref, UserRow row) async {
    final enabling = !row.mfaEnabled;
    final confirmed = await ConfirmDialog.show(
      context,
      title: '${enabling ? "Enable" : "Disable"} MFA for ${row.fullName}?',
      body: enabling
          ? 'They will be required to complete multi-factor authentication on their next sign-in.'
          : 'Their role may still mandate MFA independently of this setting — this only affects roles that don\'t already require it.',
      okLabel: enabling ? 'Enable MFA' : 'Disable MFA',
    );
    if (confirmed == null) return;

    try {
      await ref.read(usersApiProvider).updateMfaEnabled(row.id, enabling);
      ref.invalidate(usersListProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(enabling ? 'MFA enabled.' : 'MFA disabled.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _resetMfaEnrollment(BuildContext context, WidgetRef ref, UserRow row) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: "Reset ${row.fullName}'s MFA enrollment?",
      body: 'Removes every enrolled factor (authenticator app, backup codes). Use this when a user has lost their device — they will be asked to enroll again next time MFA is required.',
      okLabel: 'Reset enrollment',
      danger: true,
    );
    if (confirmed == null) return;

    try {
      await ref.read(usersApiProvider).resetMfaEnrollment(row.id);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MFA enrollment reset.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final usersAsync = ref.watch(usersListProvider);
    final filters = ref.watch(usersFiltersProvider);
    final departmentsAsync = ref.watch(departmentsListProvider);
    final roles = ref.watch(rolesProvider).valueOrNull ?? const <RoleRow>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Administration / Users & Groups', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _createUser(context, ref),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add user'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String?>(
                initialValue: filters.role,
                isDense: true,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Role', isDense: true),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All roles')),
                  for (final r in roles) DropdownMenuItem(value: r.name, child: Text(r.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => ref.read(usersFiltersProvider.notifier).state = filters.copyWith(role: () => v),
              ),
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<int?>(
                initialValue: filters.departmentId,
                isDense: true,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Department', isDense: true),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All departments')),
                  ...?departmentsAsync.valueOrNull?.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => ref.read(usersFiltersProvider.notifier).state = filters.copyWith(departmentId: () => v),
              ),
            ),
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<String?>(
                initialValue: filters.status,
                isDense: true,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Status', isDense: true),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All statuses')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'locked', child: Text('Locked')),
                  DropdownMenuItem(value: 'inactive', child: Text('Deactivated')),
                ],
                onChanged: (v) => ref.read(usersFiltersProvider.notifier).state = filters.copyWith(status: () => v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        usersAsync.when(
          loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(12),
            child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.bad)),
          ),
          data: (users) {
            if (users.isEmpty) return const EmptyState(message: 'No users found.');
            return Container(
              decoration: BoxDecoration(border: Border.all(color: tokens.line)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: tokens.surf2,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text('Name / Email', style: Theme.of(context).textTheme.labelSmall)),
                        Expanded(flex: 2, child: Text('Department', style: Theme.of(context).textTheme.labelSmall)),
                        Expanded(flex: 2, child: Text('Role', style: Theme.of(context).textTheme.labelSmall)),
                        Expanded(flex: 2, child: Text('Status', style: Theme.of(context).textTheme.labelSmall)),
                        const SizedBox(width: 128),
                      ],
                    ),
                  ),
                  for (final u in users)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.line))),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text(u.email, style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: DropdownButton<int?>(
                              value: u.departmentId,
                              isDense: true,
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              hint: const Text('Unassigned', style: TextStyle(fontSize: 12.5)),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Unassigned', style: TextStyle(fontSize: 12.5))),
                                for (final d in departmentsAsync.valueOrNull ?? const [])
                                  DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5))),
                              ],
                              onChanged: (v) {
                                final name = v == null ? null : departmentsAsync.valueOrNull?.firstWhere((d) => d.id == v).name;
                                _changeDepartment(context, ref, u, v, name);
                              },
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: DropdownButton<int?>(
                              value: roles.where((r) => r.name == u.roleName).firstOrNull?.id,
                              isDense: true,
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              hint: Text(u.roleName, style: const TextStyle(fontSize: 12.5)),
                              items: [
                                for (final r in roles)
                                  DropdownMenuItem(value: r.id, child: Text(r.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5))),
                              ],
                              onChanged: (v) {
                                final newRole = roles.where((r) => r.id == v).firstOrNull;
                                if (newRole != null && newRole.name != u.roleName) _changeRole(context, ref, u, newRole);
                              },
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                if (!u.isActive)
                                  const StatusChip('Deactivated', tone: StatusTone.bad)
                                else
                                  StatusChip(u.isLocked ? 'Locked' : 'Active', tone: u.isLocked ? StatusTone.bad : StatusTone.ok),
                                StatusChip(u.mfaEnabled ? 'MFA on' : 'MFA off', tone: u.mfaEnabled ? StatusTone.ok : StatusTone.plain),
                                if (u.adLinked) const StatusChip('AD-linked', tone: StatusTone.info),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 128,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: u.isLocked ? 'Unlock account' : 'Lock account',
                                  icon: Icon(u.isLocked ? Icons.lock_open : Icons.lock_outline, size: 18),
                                  onPressed: () => _toggleLock(context, ref, u),
                                ),
                                if (u.isActive)
                                  IconButton(
                                    tooltip: 'Deactivate account',
                                    icon: const Icon(Icons.person_off_outlined, size: 18),
                                    onPressed: () => _deactivate(context, ref, u),
                                  ),
                                PopupMenuButton<String>(
                                  tooltip: 'More actions',
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  onSelected: (action) {
                                    switch (action) {
                                      case 'reset_password':
                                        _resetPassword(context, ref, u);
                                      case 'toggle_mfa':
                                        _toggleMfa(context, ref, u);
                                      case 'reset_mfa':
                                        _resetMfaEnrollment(context, ref, u);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'reset_password', child: Text('Reset password')),
                                    PopupMenuItem(value: 'toggle_mfa', child: Text(u.mfaEnabled ? 'Disable MFA' : 'Enable MFA')),
                                    const PopupMenuItem(value: 'reset_mfa', child: Text('Reset MFA enrollment')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _GroupsSection extends ConsumerWidget {
  const _GroupsSection();

  Future<void> _addMember(BuildContext context, WidgetRef ref, GroupRow group) async {
    final userId = await showDialog<int>(context: context, builder: (_) => AddGroupMemberDialog(group: group));
    if (userId == null) return;

    try {
      await ref.read(usersApiProvider).addGroupMember(group.id, userId);
      ref.invalidate(groupsListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added.')));
      }
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final groupsAsync = ref.watch(groupsListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GROUPS', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        groupsAsync.when(
          loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
          error: (e, _) => Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.bad)),
          data: (groups) {
            if (groups.isEmpty) return const EmptyState(message: 'No groups defined.');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final g in groups) ...[
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(g.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  if (g.description != null) Text(g.description!, style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
                                ],
                              ),
                            ),
                            OutlinedButton(onPressed: () => _addMember(context, ref, g), child: const Text('Add member')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (g.members.isEmpty) Text('No members yet.', style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
                            for (final m in g.members) StatusChip(m.fullName, tone: StatusTone.info),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
