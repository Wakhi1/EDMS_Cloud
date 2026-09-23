import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/department_row.dart';
import '../../../core/models/document_record.dart';
import '../../../core/models/folder_row.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/result_dialog.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/storage_location_icon.dart';
import '../providers/repository_providers.dart';
import 'edit_document_dialog.dart';
import 'widgets/create_folder_dialog.dart';

class RepositoryScreen extends ConsumerWidget {
  const RepositoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final showTree = width >= 900;
    final showDetails = width >= 1280;
    final detailsCollapsed = ref.watch(repositoryDetailsCollapsedProvider);
    final documentsAsync = ref.watch(repositoryDocumentsProvider);
    final recycleBin = ref.watch(repositoryRecycleBinProvider);

    final sort = ref.watch(repositorySortProvider);
    final viewMode = ref.watch(repositoryViewModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recycleBin ? 'Recycle bin' : 'Repository', style: Theme.of(context).textTheme.titleMedium),
                  Text(recycleBin ? 'Records / Repository / Recycle bin' : 'Records / Repository', style: TextStyle(fontSize: 11, color: context.tokens.ink3)),
                ],
              );
              final filterBar = _FilterBar();
              const viewToggle = _ViewModeToggle();
              const recycleToggle = _RecycleBinToggle();
              const emptyBinButton = _EmptyRecycleBinButton();
              if (constraints.maxWidth < 640) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [title, const Spacer(), emptyBinButton, recycleToggle, const SizedBox(width: 8), viewToggle]),
                    const SizedBox(height: 10),
                    filterBar,
                  ],
                );
              }
              return Row(
                children: [title, const Spacer(), filterBar, const SizedBox(width: 8), emptyBinButton, recycleToggle, const SizedBox(width: 8), viewToggle],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: _RepositoryStats(docs: documentsAsync.valueOrNull, recycleBin: recycleBin),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showTree) const SizedBox(width: 200, child: _FolderTree()),
                if (showTree) const SizedBox(width: 12),
                Expanded(
                  child: documentsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) =>
                        ErrorState(message: error is ApiException ? error.message : '$error', onRetry: () => ref.invalidate(repositoryDocumentsProvider)),
                    data: (docs) {
                      final sorted = _sortDocuments(docs, sort.column, sort.ascending);
                      return switch (viewMode) {
                        RepositoryViewMode.grid => _DocumentGrid(docs: sorted, recycleBin: recycleBin),
                        RepositoryViewMode.list => _DocumentCompactList(docs: sorted, recycleBin: recycleBin),
                        RepositoryViewMode.table => _DocumentTable(docs: sorted, recycleBin: recycleBin),
                      };
                    },
                  ),
                ),
                if (showDetails) ...[
                  const SizedBox(width: 12),
                  detailsCollapsed || ref.watch(selectedDocumentProvider) == null
                      ? const _CollapsedDetailsTab()
                      : const SizedBox(width: 260, child: _PropertiesPanel()),
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

class _RecycleBinToggle extends ConsumerWidget {
  const _RecycleBinToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final active = ref.watch(repositoryRecycleBinProvider);
    return Tooltip(
      message: active ? 'Back to Repository' : 'Recycle bin',
      child: OutlinedButton.icon(
        onPressed: () {
          ref.read(repositoryRecycleBinProvider.notifier).state = !active;
          ref.read(selectedDocumentProvider.notifier).state = null;
        },
        style: active ? OutlinedButton.styleFrom(backgroundColor: tokens.sel, foregroundColor: tokens.ink) : null,
        icon: Icon(active ? Icons.arrow_back : Icons.delete_outline, size: 16),
        label: Text(active ? 'Back' : 'Recycle bin'),
      ),
    );
  }
}

/// Only rendered while the recycle bin view is active — a permanent,
/// bulk version of the per-row Restore action's opposite: every archived
/// record the caller can edit gets marked disposed (see documents.routes.js's
/// POST /recycle-bin/empty), the same terminal state Retention & Disposal's
/// own dispose action uses. Never a literal SQL DELETE.
class _EmptyRecycleBinButton extends ConsumerStatefulWidget {
  const _EmptyRecycleBinButton();

  @override
  ConsumerState<_EmptyRecycleBinButton> createState() => _EmptyRecycleBinButtonState();
}

class _EmptyRecycleBinButtonState extends ConsumerState<_EmptyRecycleBinButton> {
  bool _emptying = false;

  Future<void> _empty() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Empty recycle bin?',
      body: 'Permanently disposes every record currently in the recycle bin. This cannot be undone from here.',
      okLabel: 'Empty recycle bin',
      danger: true,
    );
    if (confirmed == null) return;

    setState(() => _emptying = true);
    try {
      final disposed = await ref.read(documentsApiProvider).emptyRecycleBin();
      ref.invalidate(repositoryDocumentsProvider);
      ref.read(selectedDocumentProvider.notifier).state = null;
      if (mounted) {
        await ResultDialog.showSuccess(context, disposed > 0 ? '$disposed record(s) permanently disposed.' : 'Recycle bin was already empty.');
      }
    } on ApiException catch (e) {
      if (mounted) await ResultDialog.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _emptying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(repositoryRecycleBinProvider);
    if (!active) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: _emptying ? null : _empty,
        style: OutlinedButton.styleFrom(foregroundColor: context.tokens.bad),
        icon: _emptying
            ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.delete_forever_outlined, size: 16),
        label: const Text('Empty recycle bin'),
      ),
    );
  }
}

class _CollapsedDetailsTab extends ConsumerWidget {
  const _CollapsedDetailsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    return Tooltip(
      message: 'Show properties',
      child: InkWell(
        onTap: () => ref.read(repositoryDetailsCollapsedProvider.notifier).state = false,
        child: Container(
          width: 28,
          decoration: BoxDecoration(
            border: Border.all(color: tokens.line),
            color: tokens.surf,
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 10),
          child: Icon(Icons.chevron_left, size: 18, color: tokens.ink2),
        ),
      ),
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
      width: 240,
      height: 32,
      child: TextField(
        controller: _controller,
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(isDense: true, hintText: 'Filter this folder…', prefixIcon: Icon(Icons.search, size: 16)),
        onSubmitted: (q) {
          final filters = ref.read(repositoryFiltersProvider);
          ref.read(repositoryFiltersProvider.notifier).state = filters.copyWith(q: q);
        },
      ),
    );
  }
}

class _ViewModeToggle extends ConsumerWidget {
  const _ViewModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final mode = ref.watch(repositoryViewModeProvider);

    Widget button(RepositoryViewMode value, IconData icon, String tooltip) {
      final selected = mode == value;
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => ref.read(repositoryViewModeProvider.notifier).state = value,
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            color: selected ? tokens.sel : Colors.transparent,
            child: Icon(icon, size: 16, color: selected ? tokens.accD : tokens.ink2),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(RepositoryViewMode.list, PhosphorIconsRegular.listBullets, 'List view'),
          Container(width: 1, height: 30, color: tokens.line),
          button(RepositoryViewMode.table, PhosphorIconsRegular.table, 'Table view'),
          Container(width: 1, height: 30, color: tokens.line),
          button(RepositoryViewMode.grid, PhosphorIconsRegular.squaresFour, 'Grid view'),
        ],
      ),
    );
  }
}

/// Compact figures for exactly what's in view (the current folder/filter),
/// computed from the already-loaded page — no extra request.
class _RepositoryStats extends StatelessWidget {
  const _RepositoryStats({required this.docs, required this.recycleBin});

  final List<DocumentRecord>? docs;
  final bool recycleBin;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final list = docs;
    int count(String status) => list?.where((d) => d.status == status).length ?? 0;
    final pages = list?.fold<int>(0, (s, d) => s + (d.pageCount ?? 0));
    final estimated = list?.any((d) => d.pageCountEstimated) ?? false;
    final bytes = list?.fold<int>(0, (s, d) => s + (d.sizeBytes ?? 0));
    final types = list?.map((d) => d.documentType).whereType<String>().toSet().length;

    final stats = <(IconData, String, String, Color?)>[
      (PhosphorIconsRegular.files, recycleBin ? 'In bin' : 'Records', list == null ? '…' : '${list.length}', null),
      if (!recycleBin) ...[
        (PhosphorIconsRegular.pencilSimpleLine, 'Draft', '${count('draft')}', tokens.acc2),
        (PhosphorIconsRegular.hourglassMedium, 'Pending', '${count('pending_approval')}', tokens.warn),
        (PhosphorIconsRegular.sealCheck, 'Approved', '${count('approved') + count('declared_final')}', tokens.ok),
      ],
      (PhosphorIconsRegular.bookOpenText, 'Pages', pages == null ? '…' : '${estimated ? '~' : ''}$pages', null),
      (PhosphorIconsRegular.hardDrives, 'Size', bytes == null ? '…' : _formatSize(bytes), null),
      (PhosphorIconsRegular.tag, 'Types', types == null ? '…' : '$types', null),
    ];

    return Container(
      decoration: BoxDecoration(
        color: tokens.surf,
        border: Border.all(color: tokens.line),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final perRow = constraints.maxWidth >= 760 ? stats.length : (constraints.maxWidth >= 420 ? 4 : 2);
          final cellWidth = (constraints.maxWidth - 2) / perRow;
          return Wrap(
            children: [
              for (var i = 0; i < stats.length; i++)
                Container(
                  width: cellWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(right: i % perRow == perRow - 1 ? BorderSide.none : BorderSide(color: tokens.line)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        color: (stats[i].$4 ?? tokens.accD).withValues(alpha: 0.1),
                        child: Icon(stats[i].$1, size: 14, color: stats[i].$4 ?? tokens.accD),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stats[i].$3,
                              maxLines: 1,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tokens.ink, height: 1.15),
                            ),
                            Text(
                              stats[i].$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5, color: tokens.ink2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _formatSize(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit += 1;
  }
  return '${value.toStringAsFixed(unit == 0 || value >= 100 ? 0 : 1)} ${units[unit]}';
}

String _date(String? iso) => iso?.split('T').first.split(' ').first ?? '—';

List<DocumentRecord> _sortDocuments(List<DocumentRecord> docs, RepositorySortColumn? column, bool ascending) {
  if (column == null) return docs;
  int compare(DocumentRecord a, DocumentRecord b) => switch (column) {
    RepositorySortColumn.recordNo => a.recordNo.compareTo(b.recordNo),
    RepositorySortColumn.title => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    RepositorySortColumn.type => (a.documentType ?? '').compareTo(b.documentType ?? ''),
    RepositorySortColumn.status => a.status.compareTo(b.status),
    RepositorySortColumn.pages => (a.pageCount ?? -1).compareTo(b.pageCount ?? -1),
    RepositorySortColumn.registered => (a.createdAt ?? '').compareTo(b.createdAt ?? ''),
  };
  final sorted = [...docs]..sort(compare);
  return ascending ? sorted : sorted.reversed.toList();
}

/// Icon buttons without Material's 48px tap-target padding, so rows stay dense.
final _compactIconStyle = IconButton.styleFrom(
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  visualDensity: VisualDensity.compact,
  minimumSize: const Size(26, 26),
  padding: EdgeInsets.zero,
);

final _fileplanSearchProvider = StateProvider.autoDispose<String>((ref) => '');

/// Folder ids currently collapsed in the File Plan tree (their descendants
/// are hidden). Ignored while searching — a search result should never be
/// hidden by a collapse state the user set up while browsing normally.
final _collapsedFolderIdsProvider = StateProvider.autoDispose<Set<int>>((ref) => {});

class _FolderTree extends ConsumerWidget {
  const _FolderTree();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final foldersAsync = ref.watch(foldersProvider);
    final filters = ref.watch(repositoryFiltersProvider);
    final search = ref.watch(_fileplanSearchProvider);

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
            child: Row(
              children: [
                Expanded(child: Text('FILE PLAN', style: Theme.of(context).textTheme.labelSmall)),
                IconButton(
                  style: _compactIconStyle,
                  tooltip: 'New folder',
                  icon: Icon(Icons.create_new_folder_outlined, size: 16, color: tokens.ink2),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () => _createFolder(context, ref, folders: foldersAsync.valueOrNull ?? const [], initialParentId: filters.folderId),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: 30,
              child: TextField(
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(isDense: true, hintText: 'Search folders…', prefixIcon: Icon(Icons.search, size: 14)),
                onChanged: (v) => ref.read(_fileplanSearchProvider.notifier).state = v,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            // Explicit ScrollController + always-visible Scrollbar: a plain
            // SingleChildScrollView scrolls fine but gives no visual hint
            // that there's more below the fold once a company has enough
            // folders to overflow this fixed-width panel.
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (search.trim().isEmpty)
                      _FolderRow(
                        label: 'All records',
                        selected: filters.folderId == null,
                        onTap: () {
                          ref.read(repositoryFiltersProvider.notifier).state = filters.copyWith(folderId: () => null);
                        },
                      ),
                    foldersAsync.when(
                      loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text('$e', style: TextStyle(color: tokens.bad, fontSize: 11)),
                      ),
                      data: (folders) {
                        final q = search.trim().toLowerCase();
                        final sorted = [...folders]..sort((a, b) => a.path.compareTo(b.path));
                        final matched = q.isEmpty ? sorted : sorted.where((f) => f.name.toLowerCase().contains(q) || f.path.toLowerCase().contains(q)).toList();
                        if (q.isNotEmpty && matched.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text('No folders match "$search".', style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
                          );
                        }

                        final byId = {for (final f in folders) f.id: f};
                        final parentsWithChildren = folders.map((f) => f.parentId).whereType<int>().toSet();
                        final collapsed = ref.watch(_collapsedFolderIdsProvider);

                        bool hasCollapsedAncestor(FolderRow f) {
                          var current = f.parentId;
                          while (current != null) {
                            if (collapsed.contains(current)) return true;
                            current = byId[current]?.parentId;
                          }
                          return false;
                        }

                        // Collapse state only applies while browsing the full tree —
                        // a search result must never be hidden by an unrelated
                        // ancestor's collapsed state.
                        final visible = q.isEmpty ? matched.where((f) => !hasCollapsedAncestor(f)).toList() : matched;

                        return Column(
                          children: [
                            for (final f in visible)
                              _FolderRow(
                                label: f.name,
                                // A search match's ancestors may be filtered out, so its
                                // indent would otherwise misleadingly jump to the root —
                                // only indent by nesting depth while showing the full tree.
                                indent: q.isEmpty ? '/'.allMatches(f.path).length.clamp(0, 4) : 0,
                                selected: filters.folderId == f.id,
                                folderId: f.id,
                                storageProviders: f.storageProviders,
                                hasChildren: q.isEmpty && parentsWithChildren.contains(f.id),
                                collapsed: collapsed.contains(f.id),
                                onToggleCollapse: () => ref.read(_collapsedFolderIdsProvider.notifier).update((s) {
                                  final next = {...s};
                                  if (!next.remove(f.id)) next.add(f.id);
                                  return next;
                                }),
                                onTap: () {
                                  ref.read(repositoryFiltersProvider.notifier).state = filters.copyWith(folderId: () => f.id);
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
    this.storageProviders,
    this.hasChildren = false,
    this.collapsed = false,
    this.onToggleCollapse,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int indent;
  final int? folderId;
  final String? storageProviders;

  /// Whether this folder has subfolders — only then is a collapse chevron
  /// shown at all, to avoid clutter on every leaf folder.
  final bool hasChildren;
  final bool collapsed;
  final VoidCallback? onToggleCollapse;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final newName = await ConfirmDialog.show(context, title: 'Rename "$label"', fieldLabel: 'Folder name', initialFieldValue: label, okLabel: 'Rename');
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
      if (context.mounted) await ResultDialog.showSuccess(context, 'Folder deleted.');
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    Widget row({bool hovering = false}) => Container(
      padding: EdgeInsets.fromLTRB(10 + indent * 12, 6, 4, 6),
      decoration: BoxDecoration(
        color: hovering ? tokens.acc.withValues(alpha: 0.18) : (selected ? tokens.sel : Colors.transparent),
        border: Border(
          bottom: BorderSide(color: tokens.line),
          left: hovering ? BorderSide(color: tokens.accD, width: 3) : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: hasChildren
                ? InkWell(
                    onTap: onToggleCollapse,
                    child: Icon(collapsed ? Icons.chevron_right : Icons.expand_more, size: 15, color: tokens.ink2),
                  )
                : null,
          ),
          Icon(PhosphorIconsDuotone.folder, size: 15, color: tokens.accD),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: selected ? tokens.ink : tokens.ink2),
            ),
          ),
          if (storageProviders != null) ...[StorageLocationIcon(provider: storageProviders, size: 12, color: tokens.ink3), const SizedBox(width: 4)],
          if (folderId != null)
            IconButton(
              style: _compactIconStyle,
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
              child: SizedBox(width: 24, height: 24, child: Icon(PhosphorIconsBold.dotsThreeVertical, size: 14, color: tokens.ink2)),
              itemBuilder: (_) => const [PopupMenuItem(value: 'rename', child: Text('Rename')), PopupMenuItem(value: 'delete', child: Text('Delete'))],
              onSelected: (v) => v == 'rename' ? _rename(context, ref) : _delete(context, ref),
            ),
        ],
      ),
    );

    if (folderId == null) {
      return InkWell(onTap: onTap, child: row());
    }

    return DragTarget<DocumentRecord>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => _moveDocument(context, ref, details.data, folderId: folderId!, folderLabel: label),
      builder: (context, candidateData, rejectedData) {
        return InkWell(
          onTap: onTap,
          child: row(hovering: candidateData.isNotEmpty),
        );
      },
    );
  }
}

/// Creates a subfolder of [initialParentId] (or a root-level folder if
/// null), with an optional default storage location — the sole folder-
/// creation entry point in the app; see CreateFolderDialog's doc comment.
Future<void> _createFolder(BuildContext context, WidgetRef ref, {required List<FolderRow> folders, int? initialParentId}) async {
  final result = await CreateFolderDialog.show(context, folders: folders, initialParentId: initialParentId);
  if (result == null) return;

  try {
    await ref
        .read(foldersApiProvider)
        .create(name: result.name, parentId: result.parentId, storageProviderId: result.storageProviderId, storagePrefix: result.storagePrefix);
    ref.invalidate(foldersProvider);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Folder created.')));
  } on ApiException catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  }
}

Future<void> _editDocument(BuildContext context, WidgetRef ref, DocumentRecord doc) async {
  // Fetched directly (not via the cached providers' .valueOrNull) since
  // neither is necessarily already warm on this screen — Repository never
  // watches documentTypesProvider itself, so a cold read here silently
  // handed the dialog an empty type list before this fix. Departments is
  // additionally silent403: a role without the 'departments' module (most
  // roles) must still be able to edit a document; it just can't see/change
  // which department it's filed under.
  final types = await ref.read(documentTypesApiProvider).list();
  final folders = await ref.read(foldersApiProvider).list();
  List<DepartmentRow> departments;
  try {
    departments = await ref.read(departmentsApiProvider).list(silent403: true);
  } on ApiException {
    departments = const <DepartmentRow>[];
  }
  if (!context.mounted) return;

  final result =
      await showDialog<
        ({
          String title,
          int documentTypeId,
          int folderId,
          int? departmentId,
          String classification,
          String watermarkMode,
          String? memberNumber,
          String? memberName,
        })
      >(
        context: context,
        builder: (_) => EditDocumentDialog(doc: doc, types: types, folders: folders, departments: departments),
      );
  if (result == null) return;

  try {
    await ref
        .read(documentsApiProvider)
        .update(
          doc.id,
          title: result.title,
          documentTypeId: result.documentTypeId,
          folderId: result.folderId,
          departmentId: result.departmentId,
          classification: result.classification,
          watermarkMode: result.watermarkMode,
          memberNumber: result.memberNumber,
          memberName: result.memberName,
        );
    ref.invalidate(repositoryDocumentsProvider);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record updated.')));
  } on ApiException catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  }
}

Future<void> _deleteDocument(BuildContext context, WidgetRef ref, DocumentRecord doc) async {
  final confirmed = await ConfirmDialog.show(
    context,
    title: 'Delete "${doc.title}"?',
    body: 'Moves the record to the recycle bin — it can be restored from there later.',
    okLabel: 'Delete',
    danger: true,
  );
  if (confirmed == null) return;

  try {
    await ref.read(documentsApiProvider).delete(doc.id);
    if (ref.read(selectedDocumentProvider)?.id == doc.id) ref.read(selectedDocumentProvider.notifier).state = null;
    ref.invalidate(repositoryDocumentsProvider);
    if (context.mounted) await ResultDialog.showSuccess(context, 'Record moved to recycle bin.');
  } on ApiException catch (e) {
    if (context.mounted) await ResultDialog.showError(context, e.message);
  }
}

Future<void> _restoreDocument(BuildContext context, WidgetRef ref, DocumentRecord doc) async {
  try {
    await ref.read(documentsApiProvider).restore(doc.id);
    if (ref.read(selectedDocumentProvider)?.id == doc.id) ref.read(selectedDocumentProvider.notifier).state = null;
    ref.invalidate(repositoryDocumentsProvider);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record restored.')));
  } on ApiException catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  }
}

Future<void> _moveDocument(BuildContext context, WidgetRef ref, DocumentRecord doc, {required int folderId, required String folderLabel}) async {
  try {
    await ref.read(documentsApiProvider).update(doc.id, folderId: folderId);
    ref.invalidate(repositoryDocumentsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Moved "${doc.title}" to $folderLabel.')));
    }
  } on ApiException catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// Per-document quick actions — "Manage access" jumps straight to the
/// folder/document access screen without opening the record first (the
/// only other way in was via the Viewer). Recycle-bin mode swaps the whole
/// menu for a single Restore action.
class _DocumentActionsButton extends ConsumerWidget {
  const _DocumentActionsButton({required this.doc, required this.recycleBin});

  final DocumentRecord doc;
  final bool recycleBin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    if (recycleBin) {
      return IconButton(
        style: _compactIconStyle,
        tooltip: 'Restore',
        icon: Icon(Icons.restore_from_trash_outlined, size: 17, color: tokens.ink2),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        onPressed: () => _restoreDocument(context, ref, doc),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          style: _compactIconStyle,
          tooltip: 'Manage access',
          icon: Icon(Icons.lock_outline, size: 15, color: tokens.ink2),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
          onPressed: () => context.go('/permissions/document/${doc.id}'),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          tooltip: 'More',
          padding: EdgeInsets.zero,
          child: SizedBox(width: 26, height: 26, child: Icon(PhosphorIconsBold.dotsThreeVertical, size: 15, color: tokens.ink2)),
          itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))],
          onSelected: (v) => v == 'edit' ? _editDocument(context, ref, doc) : _deleteDocument(context, ref, doc),
        ),
      ],
    );
  }
}

/// Opens a record in the viewer, remembering it as the selection.
void _openDocument(BuildContext context, WidgetRef ref, DocumentRecord d) {
  ref.read(selectedDocumentProvider.notifier).state = d;
  context.go(RoutePaths.viewerFor('${d.id}'));
}

/// Wraps a row/card so it can be dragged onto a File Plan folder (not in the recycle bin).
Widget _draggable(DocumentRecord d, bool recycleBin, Widget content, VoidCallback onTap) {
  final tappable = InkWell(onTap: onTap, child: content);
  if (recycleBin) return tappable;
  return Draggable<DocumentRecord>(
    data: d,
    feedback: _DragFeedback(doc: d),
    childWhenDragging: Opacity(opacity: 0.4, child: content),
    child: tappable,
  );
}

/// Full-column table with sortable headers.
class _DocumentTable extends ConsumerWidget {
  const _DocumentTable({required this.docs, required this.recycleBin});

  final List<DocumentRecord> docs;
  final bool recycleBin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (docs.isEmpty) return const EmptyState(message: 'No records match. Try clearing the filters.');
    final tokens = context.tokens;
    final selected = ref.watch(selectedDocumentProvider);
    final sort = ref.watch(repositorySortProvider);

    const columns = <(String, int, RepositorySortColumn?)>[
      ('Record no.', 3, RepositorySortColumn.recordNo),
      ('Title', 5, RepositorySortColumn.title),
      ('Type', 3, RepositorySortColumn.type),
      ('Department', 2, null),
      ('Status', 3, RepositorySortColumn.status),
      ('Pages', 1, RepositorySortColumn.pages),
      ('Registered', 2, RepositorySortColumn.registered),
    ];

    Widget header((String, int, RepositorySortColumn?) c) {
      final (label, flex, column) = c;
      final active = column != null && sort.column == column;
      final text = Row(
        children: [
          Flexible(
            child: Text(
              label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, letterSpacing: 0.5, fontWeight: FontWeight.w700, color: active ? tokens.ink : tokens.ink2),
            ),
          ),
          if (active) Icon(sort.ascending ? PhosphorIconsBold.caretUp : PhosphorIconsBold.caretDown, size: 10, color: tokens.ink),
        ],
      );
      return Expanded(
        flex: flex,
        child: column == null
            ? text
            : InkWell(onTap: () => ref.read(repositorySortProvider.notifier).state = (column: column, ascending: active ? !sort.ascending : true), child: text),
      );
    }

    Widget cell(int flex, Widget child) => Expanded(flex: flex, child: child);
    Text plain(String s, {Color? color, FontWeight? weight}) => Text(
      s,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: TextStyle(fontSize: 12.5, color: color, fontWeight: weight),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.line),
        color: tokens.surf,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: tokens.surf2,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(children: [for (final c in columns) header(c), const SizedBox(width: 64)]),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: docs.length,
              itemExtent: 36,
              itemBuilder: (context, i) {
                final d = docs[i];
                final content = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: selected?.id == d.id ? tokens.sel : (i.isOdd ? tokens.surf2.withValues(alpha: 0.35) : null),
                    border: Border(top: BorderSide(color: tokens.line)),
                  ),
                  child: Row(
                    children: [
                      cell(
                        3,
                        Row(
                          children: [
                            Flexible(
                              child: plain(d.recordNo, color: tokens.accD, weight: FontWeight.w600),
                            ),
                            if (d.storageProvider != null) ...[
                              const SizedBox(width: 5),
                              StorageLocationIcon(provider: d.storageProvider, size: 12, color: tokens.ink3),
                            ],
                          ],
                        ),
                      ),
                      cell(
                        5,
                        Row(
                          children: [
                            Icon(_iconForMime(d.mimeType), size: 15, color: tokens.ink3),
                            const SizedBox(width: 6),
                            Expanded(child: plain(d.title, weight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      cell(3, plain(d.documentType ?? '—', color: tokens.ink2)),
                      cell(2, plain(d.department ?? '—', color: tokens.ink2)),
                      cell(3, Align(alignment: Alignment.centerLeft, child: StatusChip.forDocumentStatus(d.status))),
                      cell(1, plain(d.pagesLabel, color: tokens.ink2)),
                      cell(2, plain(_date(d.createdAt), color: tokens.ink2)),
                      SizedBox(
                        width: 64,
                        child: _DocumentActionsButton(doc: d, recycleBin: recycleBin),
                      ),
                    ],
                  ),
                );
                return _draggable(d, recycleBin, content, () => _openDocument(context, ref, d));
              },
            ),
          ),
          _FooterCount(count: docs.length),
        ],
      ),
    );
  }
}

/// Dense single-line rows: icon, title over record no. + type, then status,
/// pages, size and date — scannable without the width of the full table.
class _DocumentCompactList extends ConsumerWidget {
  const _DocumentCompactList({required this.docs, required this.recycleBin});

  final List<DocumentRecord> docs;
  final bool recycleBin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (docs.isEmpty) return const EmptyState(message: 'No records match. Try clearing the filters.');
    final tokens = context.tokens;
    final selected = ref.watch(selectedDocumentProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.line),
        color: tokens.surf,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: docs.length,
              itemExtent: 46,
              itemBuilder: (context, i) {
                final d = docs[i];
                final meta = [d.recordNo, if (d.documentType != null) d.documentType!, if (d.folderPath != null) d.folderPath!].join(' · ');
                final content = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: selected?.id == d.id ? tokens.sel : null,
                    border: Border(bottom: BorderSide(color: tokens.line)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        color: tokens.accT,
                        child: Icon(_iconForMime(d.mimeType), size: 15, color: tokens.accD),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: tokens.ink3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip.forDocumentStatus(d.status),
                      SizedBox(
                        width: 58,
                        child: Text(
                          '${d.pagesLabel} pg',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 11, color: tokens.ink2),
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          d.sizeBytes == null ? '—' : _formatSize(d.sizeBytes!),
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 11, color: tokens.ink2),
                        ),
                      ),
                      SizedBox(
                        width: 82,
                        child: Text(
                          _date(d.createdAt),
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 11, color: tokens.ink2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _DocumentActionsButton(doc: d, recycleBin: recycleBin),
                    ],
                  ),
                );
                return _draggable(d, recycleBin, content, () => _openDocument(context, ref, d));
              },
            ),
          ),
          _FooterCount(count: docs.length),
        ],
      ),
    );
  }
}

class _FooterCount extends StatelessWidget {
  const _FooterCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tokens.surf2,
        border: Border(top: BorderSide(color: tokens.line)),
      ),
      child: Text('$count record${count == 1 ? '' : 's'}', style: TextStyle(fontSize: 11, color: tokens.ink2)),
    );
  }
}

/// File-type icon from the current version's mime type — the list endpoint
/// joins document_versions in for this (see documents.routes.js), so it's
/// available on every row already fetched for the list view; no extra
/// request per card. Falls back to a generic file icon when unknown (e.g.
/// the mime type wasn't recognised, or a pre-migration row has none).
IconData _iconForMime(String? mimeType) {
  final m = mimeType ?? '';
  if (m.startsWith('image/')) return Icons.image_outlined;
  if (m == 'application/pdf') return Icons.picture_as_pdf_outlined;
  if (m == 'text/csv' || m.contains('spreadsheet') || m.contains('excel')) return Icons.table_chart_outlined;
  if (m.contains('wordprocessingml') || m.contains('msword')) return Icons.description_outlined;
  if (m == 'text/plain') return Icons.article_outlined;
  return Icons.insert_drive_file_outlined;
}

/// Small drag-feedback chip shown under the cursor while moving a document
/// between folders — a full row/card would be too heavy to drag around.
class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.doc});

  final DocumentRecord doc;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      elevation: 4,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: tokens.accD),
          color: tokens.surf,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconForMime(doc.mimeType), size: 16, color: tokens.accD),
            const SizedBox(width: 6),
            Flexible(
              child: Text(doc.title, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small cards — icon, title, record no., status and a meta line. Tight
/// extent so many fit on screen without the grid feeling bulky.
class _DocumentGrid extends ConsumerWidget {
  const _DocumentGrid({required this.docs, required this.recycleBin});

  final List<DocumentRecord> docs;
  final bool recycleBin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (docs.isEmpty) return const EmptyState(message: 'No records match. Try clearing the filters.');
    final tokens = context.tokens;
    final selected = ref.watch(selectedDocumentProvider);

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 230, mainAxisExtent: 110, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: docs.length,
      itemBuilder: (context, i) {
        final d = docs[i];
        final isSelected = selected?.id == d.id;
        final card = Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 2, 8),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? tokens.accD : tokens.line),
            color: isSelected ? tokens.sel : tokens.surf,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    color: tokens.accT,
                    child: Icon(_iconForMime(d.mimeType), size: 16, color: tokens.accD),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          d.recordNo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: tokens.accD),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                d.documentType ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: tokens.ink2),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  StatusChip.forDocumentStatus(d.status),
                  const Spacer(),
                  Text('${d.pagesLabel} pg', style: TextStyle(fontSize: 10.5, color: tokens.ink3)),
                  if (d.storageProvider != null) ...[const SizedBox(width: 5), StorageLocationIcon(provider: d.storageProvider, size: 11, color: tokens.ink3)],
                  const SizedBox(width: 2),
                  _DocumentActionsButton(doc: d, recycleBin: recycleBin),
                ],
              ),
            ],
          ),
        );
        return _draggable(d, recycleBin, card, () => _openDocument(context, ref, d));
      },
    );
  }
}

class _PropertiesPanel extends ConsumerWidget {
  const _PropertiesPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final doc = ref.watch(selectedDocumentProvider);

    final collapseButton = Align(
      alignment: Alignment.topRight,
      child: IconButton(
        style: _compactIconStyle,
        tooltip: 'Hide properties',
        icon: Icon(Icons.chevron_right, size: 18, color: tokens.ink2),
        onPressed: () => ref.read(repositoryDetailsCollapsedProvider.notifier).state = true,
      ),
    );

    if (doc == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: tokens.line),
          color: tokens.surf,
        ),
        child: Column(
          children: [
            collapseButton,
            const Expanded(child: EmptyState(message: 'Select a record to see its properties.')),
          ],
        ),
      );
    }

    final rows = <(String, String)>[
      ('Type', doc.documentType ?? '—'),
      ('Department', doc.department ?? '—'),
      ('Custodian', doc.ownerName ?? '—'),
      ('Status', doc.status.replaceAll('_', ' ')),
      ('Version', doc.currentVersionNo != null ? 'v${doc.currentVersionNo}' : '—'),
      ('Pages', doc.pagesLabel),
      ('Classification', doc.classification),
      ('File plan', doc.folderPath ?? '—'),
      ('Storage', doc.storageProvider != null ? storageProviderIconAndLabel(doc.storageProvider!).$2 : '—'),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.line),
        color: tokens.surf,
      ),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            collapseButton,
            Text(doc.title, style: Theme.of(context).textTheme.titleSmall),
            Text(doc.recordNo, style: TextStyle(fontSize: 12, color: tokens.ink2)),
            const SizedBox(height: 10),
            for (final (k, v) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 88, child: Text(k.toUpperCase(), style: Theme.of(context).textTheme.labelSmall)),
                    Expanded(child: Text(v, style: const TextStyle(fontSize: 12.5))),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: () => context.go(RoutePaths.viewerFor('${doc.id}')), child: const Text('Open in viewer')),
            ),
          ],
        ),
      ),
    );
  }
}
