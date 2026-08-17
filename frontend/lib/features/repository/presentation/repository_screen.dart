import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/document_record.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../providers/repository_providers.dart';

class RepositoryScreen extends ConsumerWidget {
  const RepositoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final showTree = width >= 900;
    final showDetails = width >= 1280;
    final documentsAsync = ref.watch(repositoryDocumentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final title = Text(
                'Records / Repository',
                style: Theme.of(context).textTheme.titleMedium,
              );
              final filterBar = _FilterBar();
              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 10), filterBar],
                );
              }
              return Row(
                children: [title, const Spacer(), filterBar],
              );
            },
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showTree) const SizedBox(width: 190, child: _FolderTree()),
                if (showTree) const SizedBox(width: 16),
                Expanded(
                  child: documentsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => ErrorState(
                      message: error is ApiException ? error.message : '$error',
                      onRetry: () =>
                          ref.invalidate(repositoryDocumentsProvider),
                    ),
                    data: (docs) => _DocumentList(docs: docs),
                  ),
                ),
                if (showDetails) ...[
                  const SizedBox(width: 16),
                  const SizedBox(width: 280, child: _PropertiesPanel()),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _FilterBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<_FilterBar> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 34,
      child: TextField(
        controller: _controller,
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
          isDense: true,
          hintText: 'Filter this folder…',
          prefixIcon: Icon(Icons.search, size: 16),
        ),
        onSubmitted: (q) {
          final filters = ref.read(repositoryFiltersProvider);
          ref.read(repositoryFiltersProvider.notifier).state = filters.copyWith(
            q: q,
          );
        },
      ),
    );
  }
}

class _FolderTree extends ConsumerWidget {
  const _FolderTree();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final foldersAsync = ref.watch(foldersProvider);
    final filters = ref.watch(repositoryFiltersProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.line),
        color: tokens.surf,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              'FILE PLAN',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _FolderRow(
                    label: 'All records',
                    selected: filters.folderId == null,
                    onTap: () {
                      ref.read(repositoryFiltersProvider.notifier).state =
                          filters.copyWith(folderId: () => null);
                    },
                  ),
                  foldersAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        '$e',
                        style: TextStyle(color: tokens.bad, fontSize: 11),
                      ),
                    ),
                    data: (folders) {
                      final sorted = [...folders]
                        ..sort((a, b) => a.path.compareTo(b.path));
                      return Column(
                        children: [
                          for (final f in sorted)
                            _FolderRow(
                              label: f.name,
                              indent: '/'.allMatches(f.path).length.clamp(0, 4),
                              selected: filters.folderId == f.id,
                              folderId: f.id,
                              onTap: () {
                                ref.read(repositoryFiltersProvider.notifier).state =
                                    filters.copyWith(folderId: () => f.id);
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderRow extends ConsumerWidget {
  const _FolderRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.indent = 0,
    this.folderId,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int indent;
  final int? folderId;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final newName = await ConfirmDialog.show(
      context,
      title: 'Rename "$label"',
      fieldLabel: 'Folder name',
      initialFieldValue: label,
      okLabel: 'Rename',
    );
    if (newName == null || newName.trim().isEmpty || newName.trim() == label) return;

    try {
      await ref.read(foldersApiProvider).update(folderId!, name: newName.trim());
      ref.invalidate(foldersProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Folder renamed.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete "$label"?',
      body: 'Refused if this folder still contains subfolders or documents.',
      okLabel: 'Delete',
      danger: true,
    );
    if (confirmed == null) return;

    try {
      await ref.read(foldersApiProvider).delete(folderId!);
      ref.invalidate(foldersProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Folder deleted.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(10 + indent * 12, 6, 4, 6),
        decoration: BoxDecoration(
          color: selected ? tokens.sel : Colors.transparent,
          border: Border(bottom: BorderSide(color: tokens.line)),
        ),
        child: Row(
          children: [
            Icon(PhosphorIconsDuotone.folder, size: 15, color: tokens.accD),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: selected ? tokens.ink : tokens.ink2,
                ),
              ),
            ),
            if (folderId != null)
              IconButton(
                tooltip: 'Manage access',
                icon: Icon(PhosphorIconsDuotone.lockKey, size: 15, color: tokens.ink2),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => context.go('/permissions/folder/$folderId'),
              ),
            if (folderId != null)
              PopupMenuButton<String>(
                tooltip: 'More',
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert, size: 15, color: tokens.ink2),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (v) => v == 'rename' ? _rename(context, ref) : _delete(context, ref),
              ),
          ],
        ),
      ),
    );
  }
}

class _DocumentList extends ConsumerWidget {
  const _DocumentList({required this.docs});

  final List<DocumentRecord> docs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (docs.isEmpty) {
      return const EmptyState(
        message: 'No records match. Try clearing the filters.',
      );
    }
    final tokens = context.tokens;
    final selected = ref.watch(selectedDocumentProvider);

    const flexes = [2, 3, 2, 2, 2, 2];

    Widget cell(String text, int flex, {Widget? child}) {
      return Expanded(
        flex: flex,
        child:
            child ?? Text(text, overflow: TextOverflow.ellipsis, maxLines: 1),
      );
    }

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
                cell('Record no.', flexes[0]),
                cell('Title', flexes[1]),
                cell('Type', flexes[2]),
                cell('Department', flexes[3]),
                cell('Status', flexes[4]),
                cell('Registered', flexes[5]),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i];
                return InkWell(
                  onTap: () {
                    ref.read(selectedDocumentProvider.notifier).state = d;
                    context.go(RoutePaths.viewerFor('${d.id}'));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected?.id == d.id ? tokens.sel : Colors.transparent,
                      border: Border(top: BorderSide(color: tokens.line)),
                    ),
                    child: Row(
                      children: [
                        cell(d.recordNo, flexes[0]),
                        cell(d.title, flexes[1]),
                        cell(d.documentType ?? '—', flexes[2]),
                        cell(d.department ?? '—', flexes[3]),
                        cell(
                          '',
                          flexes[4],
                          child: StatusChip.forDocumentStatus(d.status),
                        ),
                        cell(d.createdAt?.split('T').first ?? '—', flexes[5]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertiesPanel extends ConsumerWidget {
  const _PropertiesPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final doc = ref.watch(selectedDocumentProvider);

    if (doc == null) {
      return const EmptyState(
        message: 'Select a record to see its properties.',
      );
    }

    final rows = <(String, String)>[
      ('Type', doc.documentType ?? '—'),
      ('Department', doc.department ?? '—'),
      ('Custodian', doc.ownerName ?? '—'),
      ('Status', doc.status.replaceAll('_', ' ')),
      (
        'Version',
        doc.currentVersionNo != null ? 'v${doc.currentVersionNo}' : '—',
      ),
      ('Classification', doc.classification),
      ('File plan', doc.folderPath ?? '—'),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.line),
        color: tokens.surf,
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(doc.title, style: Theme.of(context).textTheme.titleSmall),
          Text(
            doc.recordNo,
            style: TextStyle(fontSize: 12, color: tokens.ink2),
          ),
          const SizedBox(height: 10),
          for (final (k, v) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 88,
                    child: Text(
                      k.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  Expanded(
                    child: Text(v, style: const TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go(RoutePaths.viewerFor('${doc.id}')),
              child: const Text('Open in viewer'),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
