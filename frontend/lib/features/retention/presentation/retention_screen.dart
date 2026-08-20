import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/document_type_row.dart';
import '../../../core/models/retention_class_row.dart';
import '../../../core/models/retention_due_item.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/result_dialog.dart';
import '../../repository/providers/repository_providers.dart';
import '../providers/retention_providers.dart';
import 'create_document_type_dialog.dart';
import 'create_retention_class_dialog.dart';
import 'edit_retention_class_dialog.dart';

class RetentionScreen extends StatelessWidget {
  const RetentionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1000;

    const classes = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RetentionClassesSection(),
        SizedBox(height: 20),
        _DocumentTypesSection(),
      ],
    );
    const due = _DisposalDueSection();

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Governance / Retention & Disposal', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Expanded(
            child: wide
                ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: SingleChildScrollView(child: classes)),
                      SizedBox(width: 16),
                      Expanded(child: SingleChildScrollView(child: due)),
                    ],
                  )
                : const SingleChildScrollView(
                    child: Column(children: [classes, SizedBox(height: 20), due]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RetentionClassesSection extends ConsumerWidget {
  const _RetentionClassesSection();

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String code, String name, int retentionYears, String disposalAction})>(
      context: context,
      builder: (_) => const CreateRetentionClassDialog(),
    );
    if (result == null) return;

    try {
      await ref.read(retentionApiProvider).createClass(
            code: result.code,
            name: result.name,
            retentionYears: result.retentionYears,
            disposalAction: result.disposalAction,
          );
      ref.invalidate(retentionClassesProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retention schedule created.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, RetentionClassRow row) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete ${row.code}?',
      body: 'Refused if this schedule is still assigned to folders or records.',
      okLabel: 'Delete',
      danger: true,
    );
    if (confirmed == null) return;

    try {
      await ref.read(retentionApiProvider).deleteClass(row.id);
      ref.invalidate(retentionClassesProvider);
      if (context.mounted) await ResultDialog.showSuccess(context, 'Retention schedule deleted.');
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, RetentionClassRow row) async {
    final result = await showDialog<({String name, int? retentionYears, String disposalAction})>(
      context: context,
      builder: (_) => EditRetentionClassDialog(retentionClass: row),
    );
    if (result == null) return;

    try {
      await ref.read(retentionApiProvider).updateClass(
            row.id,
            name: result.name.isNotEmpty ? result.name : null,
            retentionYears: result.retentionYears,
            disposalAction: result.disposalAction,
          );
      ref.invalidate(retentionClassesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retention schedule updated.')));
      }
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final classesAsync = ref.watch(retentionClassesProvider);

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
                Text('RETENTION CLASSES', style: textTheme.labelSmall),
                const Spacer(),
                TextButton(onPressed: () => _create(context, ref), child: const Text('+ New')),
              ],
            ),
          ),
          classesAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.bad, fontSize: 12)),
            ),
            data: (rows) {
              if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(12), child: Text('No retention classes defined.'));
              return Column(
                children: [
                  for (final r in rows)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.line))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text(
                                  '${r.code} · ${r.retentionYears}y · ${r.disposalAction.replaceAll('_', ' ')}${r.requiresRecordsManagerApproval ? ' · RM approval required' : ''}',
                                  style: TextStyle(fontSize: 11.5, color: tokens.ink2),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(onPressed: () => _edit(context, ref, r), child: const Text('Edit')),
                          const SizedBox(width: 6),
                          OutlinedButton(onPressed: () => _delete(context, ref, r), child: const Text('Delete')),
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

class _DisposalDueSection extends ConsumerWidget {
  const _DisposalDueSection();

  Future<void> _dispose(BuildContext context, WidgetRef ref, RetentionDueItem item) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Dispose ${item.recordNo}?',
      body: 'This permanently flips the record to "disposed" — it cannot be undone from this screen.',
      rows: [('Title', item.title), ('Due', item.retentionDueAt.split('T').first), ('Action', item.disposalAction.replaceAll('_', ' '))],
      okLabel: 'Dispose',
      danger: true,
    );
    if (confirmed == null) return;

    try {
      await ref.read(retentionApiProvider).dispose(item.id);
      ref.invalidate(retentionDueProvider);
      if (context.mounted) {
        await ResultDialog.showSuccess(context, '${item.recordNo} marked disposed.');
      }
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final dueAsync = ref.watch(retentionDueProvider);

    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text('DUE FOR DISPOSAL', style: textTheme.labelSmall),
          ),
          dueAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.bad, fontSize: 12)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: EmptyState(message: 'Nothing is due for disposal.'),
                );
              }
              return Column(
                children: [
                  for (final item in items)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.line))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text(
                                  '${item.recordNo} · due ${item.retentionDueAt.split('T').first} · ${item.retentionClassName ?? "—"}',
                                  style: TextStyle(fontSize: 11.5, color: tokens.ink2),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => _dispose(context, ref, item),
                            style: OutlinedButton.styleFrom(foregroundColor: tokens.bad, side: BorderSide(color: tokens.bad)),
                            child: const Text('Dispose'),
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

class _DocumentTypesSection extends ConsumerWidget {
  const _DocumentTypesSection();

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String name, String code})>(context: context, builder: (_) => const CreateDocumentTypeDialog());
    if (result == null) return;

    try {
      await ref.read(documentTypesApiProvider).create(name: result.name, code: result.code);
      ref.invalidate(documentTypesProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document type created.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, DocumentTypeRow row) async {
    final result = await showDialog<({String name, String code})>(
      context: context,
      builder: (_) => CreateDocumentTypeDialog(initialName: row.name, initialCode: row.code),
    );
    if (result == null) return;

    try {
      await ref.read(documentTypesApiProvider).update(row.id, name: result.name, code: result.code);
      ref.invalidate(documentTypesProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document type updated.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, DocumentTypeRow row) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete "${row.name}"?',
      body: 'Refused if any existing records still use this document type.',
      okLabel: 'Delete',
      danger: true,
    );
    if (confirmed == null) return;

    try {
      await ref.read(documentTypesApiProvider).delete(row.id);
      ref.invalidate(documentTypesProvider);
      if (context.mounted) await ResultDialog.showSuccess(context, 'Document type deleted.');
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final typesAsync = ref.watch(documentTypesProvider);

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
                Text('DOCUMENT TYPES', style: textTheme.labelSmall),
                const Spacer(),
                TextButton(onPressed: () => _create(context, ref), child: const Text('+ New')),
              ],
            ),
          ),
          typesAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.bad, fontSize: 12)),
            ),
            data: (rows) {
              if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(12), child: Text('No document types defined.'));
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
                                Text(r.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text(r.code, style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
                              ],
                            ),
                          ),
                          OutlinedButton(onPressed: () => _edit(context, ref, r), child: const Text('Edit')),
                          const SizedBox(width: 6),
                          OutlinedButton(onPressed: () => _delete(context, ref, r), child: const Text('Delete')),
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
