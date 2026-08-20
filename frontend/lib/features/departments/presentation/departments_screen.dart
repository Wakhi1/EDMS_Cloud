import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/department_row.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/result_dialog.dart';
import '../../../core/widgets/status_chip.dart';
import '../providers/departments_providers.dart';
import 'create_department_dialog.dart';
import 'edit_department_dialog.dart';

class DepartmentsScreen extends ConsumerWidget {
  const DepartmentsScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String name, String description})>(
      context: context,
      builder: (_) => const CreateDepartmentDialog(),
    );
    if (result == null) return;

    try {
      await ref.read(departmentsApiProvider).create(name: result.name, description: result.description.isNotEmpty ? result.description : null);
      ref.invalidate(departmentsListProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department created.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(departmentsListProvider);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Administration / Departments', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _create(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add department'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: departmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: error is ApiException ? error.message : '$error',
                onRetry: () => ref.invalidate(departmentsListProvider),
              ),
              data: (rows) {
                if (rows.isEmpty) return const EmptyState(message: 'No departments configured.');
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _DepartmentCard(row: rows[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentCard extends ConsumerWidget {
  const _DepartmentCard({required this.row});

  final DepartmentRow row;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String name, String description, bool isActive})>(
      context: context,
      builder: (_) => EditDepartmentDialog(department: row),
    );
    if (result == null) return;

    try {
      await ref.read(departmentsApiProvider).update(row.id, name: result.name, description: result.description, isActive: result.isActive);
      ref.invalidate(departmentsListProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department updated.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete ${row.name}?',
      body: 'Refused if any users or folders are still assigned to this department.',
      okLabel: 'Delete',
      danger: true,
    );
    if (confirmed == null) return;

    try {
      await ref.read(departmentsApiProvider).delete(row.id);
      ref.invalidate(departmentsListProvider);
      if (context.mounted) await ResultDialog.showSuccess(context, 'Department deleted.');
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(row.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    StatusChip(row.isActive ? 'Active' : 'Inactive', tone: row.isActive ? StatusTone.ok : StatusTone.plain),
                  ],
                ),
                if (row.description != null) ...[
                  const SizedBox(height: 4),
                  Text(row.description!, style: TextStyle(fontSize: 12, color: tokens.ink2)),
                ],
              ],
            ),
          ),
          OutlinedButton(onPressed: () => _edit(context, ref), child: const Text('Edit')),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: () => _delete(context, ref), child: const Text('Delete')),
        ],
      ),
    );
  }
}
