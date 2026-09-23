import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final sidePanel = width >= _kSidePanelBreakpoint;
    // Details pane grows with the window, like Explorer's: 240–340px.
    final panelWidth = (width * 0.2).clamp(240.0, 340.0);
    final hasSelection = ref.watch(repositorySelectionProvider).isNotEmpty;
    final overlayOpen = ref.watch(repositoryDetailsOverlayProvider);
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
              const viewToggle = Row(mainAxisSize: MainAxisSize.min, children: [_DetailsToggle(), SizedBox(width: 6), _ViewModeToggle()]);
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
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: documentsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, _) =>
                              ErrorState(message: error is ApiException ? error.message : '$error', onRetry: () => ref.invalidate(repositoryDocumentsProvider)),
                          data: (docs) {
                            final sorted = _sortDocuments(docs, sort.column, sort.ascending);
                            return _SelectionKeyboard(
                              docs: sorted,
                              recycleBin: recycleBin,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _SelectionBar(docs: sorted, recycleBin: recycleBin),
                                  Expanded(
                                    child: switch (viewMode) {
                                      RepositoryViewMode.grid => _DocumentGrid(docs: sorted, recycleBin: recycleBin),
                                      RepositoryViewMode.list => _DocumentCompactList(docs: sorted, recycleBin: recycleBin),
                                      RepositoryViewMode.table => _DocumentTable(docs: sorted, recycleBin: recycleBin),
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Narrow windows: the details pane floats over the list instead of squeezing it.
                      if (!sidePanel && overlayOpen && hasSelection)
                        Positioned(
                          top: 0,
                          right: 0,
                          bottom: 0,
                          width: panelWidth,
                          child: Material(
                            elevation: 8,
                            child: _PropertiesPanel(onClose: () => ref.read(repositoryDetailsOverlayProvider.notifier).state = false),
                          ),
                        ),
                    ],
                  ),
                ),
                if (sidePanel) ...[
                  const SizedBox(width: 12),
                  detailsCollapsed || !hasSelection ? const _CollapsedDetailsTab() : SizedBox(width: panelWidth, child: const _PropertiesPanel()),
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
          _setSelection(ref, <int>{});
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

    return DragTarget<List<DocumentRecord>>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => _moveDocuments(context, ref, details.data, folderId: folderId!, folderLabel: label),
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

/// Opens a record in the viewer, remembering it as the focused record.
void _openDocument(BuildContext context, WidgetRef ref, DocumentRecord d) {
  ref.read(selectedDocumentProvider.notifier).state = d;
  context.go(RoutePaths.viewerFor('${d.id}'));
}

/// The records currently selected, in list order.
List<DocumentRecord> _selectedDocs(WidgetRef ref, List<DocumentRecord> docs) {
  final ids = ref.read(repositorySelectionProvider);
  return docs.where((d) => ids.contains(d.id)).toList();
}

void _setSelection(WidgetRef ref, Set<int> ids, {DocumentRecord? focus, int? anchor}) {
  ref.read(repositorySelectionProvider.notifier).state = ids;
  ref.read(selectedDocumentProvider.notifier).state = ids.isEmpty ? null : focus;
  if (anchor != null) ref.read(repositorySelectionAnchorProvider.notifier).state = anchor;
}

/// Explorer-style click: plain = select one, Ctrl = toggle, Shift = range
/// from the anchor, Ctrl+Shift = add range.
void _selectAt(WidgetRef ref, List<DocumentRecord> docs, int index) {
  final keys = HardwareKeyboard.instance;
  final ctrl = keys.isControlPressed || keys.isMetaPressed;
  final shift = keys.isShiftPressed;
  final d = docs[index];
  final current = ref.read(repositorySelectionProvider);
  final anchorId = ref.read(repositorySelectionAnchorProvider);
  final anchorIndex = anchorId == null ? -1 : docs.indexWhere((x) => x.id == anchorId);

  if (shift && anchorIndex >= 0) {
    final lo = anchorIndex < index ? anchorIndex : index;
    final hi = anchorIndex < index ? index : anchorIndex;
    final range = {for (var i = lo; i <= hi; i++) docs[i].id};
    _setSelection(ref, ctrl ? {...current, ...range} : range, focus: d);
  } else if (ctrl) {
    final next = {...current};
    if (!next.remove(d.id)) next.add(d.id);
    final focus = next.contains(d.id) ? d : docs.where((x) => next.contains(x.id)).firstOrNull;
    _setSelection(ref, next, focus: focus, anchor: d.id);
  } else {
    _setSelection(ref, {d.id}, focus: d, anchor: d.id);
  }
}

/// Moves the focus by [delta] rows (arrow keys); Shift extends the selection.
void _moveFocus(WidgetRef ref, List<DocumentRecord> docs, int delta) {
  if (docs.isEmpty) return;
  final focus = ref.read(selectedDocumentProvider);
  final from = focus == null ? -1 : docs.indexWhere((d) => d.id == focus.id);
  final to = (from + delta).clamp(0, docs.length - 1);
  if (HardwareKeyboard.instance.isShiftPressed && ref.read(repositorySelectionAnchorProvider) != null) {
    _selectAt(ref, docs, to);
  } else {
    _setSelection(ref, {docs[to].id}, focus: docs[to], anchor: docs[to].id);
  }
}

/// Runs [action] for each record, then reports how many succeeded.
Future<void> _bulk(
  BuildContext context,
  WidgetRef ref,
  List<DocumentRecord> docs,
  Future<void> Function(DocumentRecord d) action, {
  required String done,
}) async {
  var ok = 0;
  final errors = <String>[];
  for (final d in docs) {
    try {
      await action(d);
      ok += 1;
    } on ApiException catch (e) {
      errors.add('${d.recordNo}: ${e.message}');
    }
  }
  ref.invalidate(repositoryDocumentsProvider);
  _setSelection(ref, <int>{});
  if (!context.mounted) return;
  if (errors.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$ok record${ok == 1 ? '' : 's'} $done.')));
  } else {
    await ResultDialog.showError(context, '$ok $done, ${errors.length} failed:\n${errors.take(8).join('\n')}');
  }
}

Future<void> _deleteDocuments(BuildContext context, WidgetRef ref, List<DocumentRecord> docs) async {
  if (docs.isEmpty) return;
  if (docs.length == 1) return _deleteDocument(context, ref, docs.first);
  final confirmed = await ConfirmDialog.show(
    context,
    title: 'Delete ${docs.length} records?',
    body: 'Moves them to the recycle bin — they can be restored from there later.',
    okLabel: 'Delete ${docs.length}',
    danger: true,
  );
  if (confirmed == null || !context.mounted) return;
  await _bulk(context, ref, docs, (d) => ref.read(documentsApiProvider).delete(d.id), done: 'moved to the recycle bin');
}

Future<void> _restoreDocuments(BuildContext context, WidgetRef ref, List<DocumentRecord> docs) async {
  if (docs.isEmpty) return;
  await _bulk(context, ref, docs, (d) => ref.read(documentsApiProvider).restore(d.id), done: 'restored');
}

Future<void> _moveDocuments(BuildContext context, WidgetRef ref, List<DocumentRecord> docs, {required int folderId, required String folderLabel}) async {
  if (docs.isEmpty) return;
  await _bulk(context, ref, docs, (d) => ref.read(documentsApiProvider).update(d.id, folderId: folderId), done: 'moved to $folderLabel');
}

/// "Move to…" — pick a destination folder from the File Plan.
Future<void> _pickFolderAndMove(BuildContext context, WidgetRef ref, List<DocumentRecord> docs) async {
  final folders = await ref.read(foldersApiProvider).list();
  if (!context.mounted) return;
  final sorted = [...folders]..sort((a, b) => a.path.compareTo(b.path));
  final picked = await showDialog<FolderRow>(
    context: context,
    builder: (context) {
      final tokens = context.tokens;
      return AlertDialog(
        title: Text('Move ${docs.length} record${docs.length == 1 ? '' : 's'} to…'),
        contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
        content: SizedBox(
          width: 380,
          height: 360,
          child: ListView(
            children: [
              for (final f in sorted)
                InkWell(
                  onTap: () => Navigator.of(context).pop(f),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.0 + 14 * ' / '.allMatches(f.path).length, 8, 20, 8),
                    child: Row(
                      children: [
                        Icon(PhosphorIconsDuotone.folder, size: 16, color: tokens.accD),
                        const SizedBox(width: 8),
                        Expanded(child: Text(f.name, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))],
      );
    },
  );
  if (picked == null || !context.mounted) return;
  await _moveDocuments(context, ref, docs, folderId: picked.id, folderLabel: picked.name);
}

/// Right-click menu — acts on the whole selection, like Explorer.
Future<void> _showContextMenu(BuildContext context, WidgetRef ref, List<DocumentRecord> docs, Offset position, bool recycleBin) async {
  final selected = _selectedDocs(ref, docs);
  if (selected.isEmpty) return;
  final single = selected.length == 1 ? selected.first : null;
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;

  PopupMenuItem<String> item(String value, IconData icon, String label, {String? shortcut, bool danger = false}) => PopupMenuItem<String>(
    value: value,
    height: 34,
    child: Row(
      children: [
        Icon(icon, size: 15, color: danger ? context.tokens.bad : context.tokens.ink2),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 12.5, color: danger ? context.tokens.bad : null)),
        ),
        if (shortcut != null) Text(shortcut, style: TextStyle(fontSize: 11, color: context.tokens.ink3)),
      ],
    ),
  );

  final choice = await showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(position & const Size(1, 1), Offset.zero & overlay.size),
    items: recycleBin
        ? [item('restore', PhosphorIconsRegular.arrowCounterClockwise, selected.length == 1 ? 'Restore' : 'Restore ${selected.length} records')]
        : [
            if (single != null) item('open', PhosphorIconsRegular.arrowSquareOut, 'Open', shortcut: 'Enter'),
            if (single != null) item('edit', PhosphorIconsRegular.pencilSimple, 'Edit properties', shortcut: 'F2'),
            if (single != null) item('versions', PhosphorIconsRegular.clockCounterClockwise, 'Version history'),
            if (single != null) item('access', PhosphorIconsRegular.lockKey, 'Manage access'),
            item('move', PhosphorIconsRegular.folderSimpleDashed, selected.length == 1 ? 'Move to…' : 'Move ${selected.length} to…'),
            const PopupMenuDivider(),
            item('delete', PhosphorIconsRegular.trash, selected.length == 1 ? 'Delete' : 'Delete ${selected.length} records', shortcut: 'Del', danger: true),
          ],
  );
  if (choice == null || !context.mounted) return;
  switch (choice) {
    case 'open':
      _openDocument(context, ref, single!);
    case 'edit':
      await _editDocument(context, ref, single!);
    case 'versions':
      context.go(RoutePaths.versionsFor('${single!.id}'));
    case 'access':
      context.go('/permissions/document/${single!.id}');
    case 'move':
      await _pickFolderAndMove(context, ref, selected);
    case 'delete':
      await _deleteDocuments(context, ref, selected);
    case 'restore':
      await _restoreDocuments(context, ref, selected);
  }
}

/// Record pressed while already selected — narrowed to on release unless a drag starts.
int? _collapseOnRelease;

/// One row/card: click/Ctrl/Shift select, double-click opens, right-click
/// menu, and dragging carries the whole selection onto a File Plan folder.
class _ItemInteraction extends ConsumerWidget {
  const _ItemInteraction({required this.docs, required this.index, required this.recycleBin, required this.child});

  final List<DocumentRecord> docs;
  final int index;
  final bool recycleBin;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = docs[index];
    final interactive = Listener(
      onPointerDown: (event) {
        if (event.buttons == kSecondaryMouseButton) {
          if (!ref.read(repositorySelectionProvider).contains(d.id)) {
            _setSelection(ref, {d.id}, focus: d, anchor: d.id);
          }
          _showContextMenu(context, ref, docs, event.position, recycleBin);
        } else if (event.buttons == kPrimaryMouseButton) {
          // Pressing on an already-selected item keeps the selection so it can be
          // dragged as a group; releasing without a drag narrows it to that item.
          final keys = HardwareKeyboard.instance;
          final modifier = keys.isControlPressed || keys.isMetaPressed || keys.isShiftPressed;
          if (modifier || !ref.read(repositorySelectionProvider).contains(d.id)) {
            _selectAt(ref, docs, index);
            _collapseOnRelease = null;
          } else {
            _collapseOnRelease = d.id;
          }
        }
      },
      onPointerUp: (_) {
        if (_collapseOnRelease == d.id) _setSelection(ref, {d.id}, focus: d, anchor: d.id);
        _collapseOnRelease = null;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: () => _openDocument(context, ref, d),
        child: MouseRegion(cursor: SystemMouseCursors.click, child: child),
      ),
    );
    if (recycleBin) return interactive;

    final selection = ref.watch(repositorySelectionProvider);
    final dragging = selection.contains(d.id) ? docs.where((x) => selection.contains(x.id)).toList() : [d];
    return Draggable<List<DocumentRecord>>(
      data: dragging,
      feedback: _DragFeedback(docs: dragging),
      onDragStarted: () => _collapseOnRelease = null,
      childWhenDragging: Opacity(opacity: 0.4, child: child),
      child: interactive,
    );
  }
}

/// Keyboard layer over the record view: Ctrl+A, Esc, Delete, Enter, F2,
/// arrows (Shift extends), Alt+Enter toggles the details panel.
class _SelectionKeyboard extends ConsumerStatefulWidget {
  const _SelectionKeyboard({required this.docs, required this.recycleBin, required this.child});

  final List<DocumentRecord> docs;
  final bool recycleBin;
  final Widget child;

  @override
  ConsumerState<_SelectionKeyboard> createState() => _SelectionKeyboardState();
}

class _SelectionKeyboardState extends ConsumerState<_SelectionKeyboard> {
  final _focusNode = FocusNode(debugLabel: 'repository-records');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final keys = HardwareKeyboard.instance;
    final ctrl = keys.isControlPressed || keys.isMetaPressed;
    final docs = widget.docs;
    final key = event.logicalKey;
    final focus = ref.read(selectedDocumentProvider);

    if (ctrl && key == LogicalKeyboardKey.keyA) {
      _setSelection(ref, {for (final d in docs) d.id}, focus: focus ?? docs.firstOrNull);
    } else if (key == LogicalKeyboardKey.escape) {
      _setSelection(ref, <int>{});
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _moveFocus(ref, docs, 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _moveFocus(ref, docs, -1);
    } else if (key == LogicalKeyboardKey.home) {
      _moveFocus(ref, docs, -docs.length);
    } else if (key == LogicalKeyboardKey.end) {
      _moveFocus(ref, docs, docs.length);
    } else if (key == LogicalKeyboardKey.enter && keys.isAltPressed) {
      _toggleDetails(ref, MediaQuery.sizeOf(context).width);
    } else if (key == LogicalKeyboardKey.enter && focus != null && event is KeyDownEvent) {
      _openDocument(context, ref, focus);
    } else if (key == LogicalKeyboardKey.f2 && focus != null && !widget.recycleBin && event is KeyDownEvent) {
      _editDocument(context, ref, focus);
    } else if (key == LogicalKeyboardKey.delete && event is KeyDownEvent) {
      final selected = _selectedDocs(ref, docs);
      widget.recycleBin ? _restoreDocuments(context, ref, selected) : _deleteDocuments(context, ref, selected);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Listener(behavior: HitTestBehavior.translucent, onPointerDown: (_) => _focusNode.requestFocus(), child: widget.child),
    );
  }
}

void _toggleDetails(WidgetRef ref, double width) {
  if (width >= _kSidePanelBreakpoint) {
    ref.read(repositoryDetailsCollapsedProvider.notifier).update((v) => !v);
  } else {
    ref.read(repositoryDetailsOverlayProvider.notifier).update((v) => !v);
  }
}

const _kSidePanelBreakpoint = 1280.0;

/// Shown while anything is selected: count plus the bulk actions.
class _SelectionBar extends ConsumerWidget {
  const _SelectionBar({required this.docs, required this.recycleBin});

  final List<DocumentRecord> docs;
  final bool recycleBin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final ids = ref.watch(repositorySelectionProvider);
    final selected = docs.where((d) => ids.contains(d.id)).toList();
    if (selected.length < 2) return const SizedBox.shrink();

    Widget action(IconData icon, String label, VoidCallback onTap, {Color? color}) => TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color ?? tokens.ink,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );

    final size = selected.fold<int>(0, (s, d) => s + (d.sizeBytes ?? 0));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.sel,
        border: Border.all(color: tokens.acc.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Text('${selected.length} selected', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          Text('  ·  ${_formatSize(size)}', style: TextStyle(fontSize: 12, color: tokens.ink2)),
          const Spacer(),
          if (recycleBin)
            action(PhosphorIconsRegular.arrowCounterClockwise, 'Restore', () => _restoreDocuments(context, ref, selected))
          else ...[
            action(PhosphorIconsRegular.folderSimpleDashed, 'Move to…', () => _pickFolderAndMove(context, ref, selected)),
            action(PhosphorIconsRegular.trash, 'Delete', () => _deleteDocuments(context, ref, selected), color: tokens.bad),
          ],
          Container(width: 1, height: 18, color: tokens.line2, margin: const EdgeInsets.symmetric(horizontal: 6)),
          action(PhosphorIconsRegular.x, 'Clear', () => _setSelection(ref, <int>{})),
        ],
      ),
    );
  }
}

/// Full-column table with sortable headers.
class _DocumentTable extends ConsumerWidget {
  const _DocumentTable({required this.docs, required this.recycleBin});

  final List<DocumentRecord> docs;
  final bool recycleBin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (docs.isEmpty) return const EmptyState(message: 'No records match. Try clearing the filters.');

    // Like Explorer's details view, lower-priority columns drop out as the
    // pane narrows (e.g. when the details pane is open) instead of squeezing.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final showDept = w >= 900;
        final showType = w >= 720;
        final showDate = w >= 620;
        final columns = <(String, int, RepositorySortColumn?)>[
          ('Record no.', 3, RepositorySortColumn.recordNo),
          ('Title', 5, RepositorySortColumn.title),
          if (showType) ('Type', 3, RepositorySortColumn.type),
          if (showDept) ('Department', 2, null),
          ('Status', 3, RepositorySortColumn.status),
          ('Pages', 1, RepositorySortColumn.pages),
          if (showDate) ('Registered', 2, RepositorySortColumn.registered),
        ];
        return _table(context, ref, columns, showType: showType, showDept: showDept, showDate: showDate);
      },
    );
  }

  Widget _table(
    BuildContext context,
    WidgetRef ref,
    List<(String, int, RepositorySortColumn?)> columns, {
    required bool showType,
    required bool showDept,
    required bool showDate,
  }) {
    final tokens = context.tokens;
    final selection = ref.watch(repositorySelectionProvider);
    final sort = ref.watch(repositorySortProvider);

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
                    color: selection.contains(d.id) ? tokens.sel : (i.isOdd ? tokens.surf2.withValues(alpha: 0.35) : null),
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
                      if (showType) cell(3, plain(d.documentType ?? '—', color: tokens.ink2)),
                      if (showDept) cell(2, plain(d.department ?? '—', color: tokens.ink2)),
                      cell(3, Align(alignment: Alignment.centerLeft, child: StatusChip.forDocumentStatus(d.status))),
                      cell(1, plain(d.pagesLabel, color: tokens.ink2)),
                      if (showDate) cell(2, plain(_date(d.createdAt), color: tokens.ink2)),
                      SizedBox(
                        width: 64,
                        child: _DocumentActionsButton(doc: d, recycleBin: recycleBin),
                      ),
                    ],
                  ),
                );
                return _ItemInteraction(docs: docs, index: i, recycleBin: recycleBin, child: content);
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
    final selection = ref.watch(repositorySelectionProvider);

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
                    color: selection.contains(d.id) ? tokens.sel : null,
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
                return _ItemInteraction(docs: docs, index: i, recycleBin: recycleBin, child: content);
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
  const _DragFeedback({required this.docs});

  final List<DocumentRecord> docs;

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
            Icon(docs.length == 1 ? _iconForMime(docs.first.mimeType) : PhosphorIconsRegular.files, size: 16, color: tokens.accD),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                docs.length == 1 ? docs.first.title : 'Move ${docs.length} records',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
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
    final selection = ref.watch(repositorySelectionProvider);

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 230, mainAxisExtent: 110, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: docs.length,
      itemBuilder: (context, i) {
        final d = docs[i];
        final isSelected = selection.contains(d.id);
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
        return _ItemInteraction(docs: docs, index: i, recycleBin: recycleBin, child: card);
      },
    );
  }
}

/// ⓘ — shows/hides the details pane (Alt+Enter does the same).
class _DetailsToggle extends ConsumerWidget {
  const _DetailsToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final width = MediaQuery.sizeOf(context).width;
    final open = width >= _kSidePanelBreakpoint ? !ref.watch(repositoryDetailsCollapsedProvider) : ref.watch(repositoryDetailsOverlayProvider);
    return Tooltip(
      message: 'Details pane (Alt+Enter)',
      child: InkWell(
        onTap: () => _toggleDetails(ref, width),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: tokens.line),
            color: open ? tokens.sel : null,
          ),
          child: Icon(PhosphorIconsRegular.sidebarSimple, size: 16, color: open ? tokens.accD : tokens.ink2),
        ),
      ),
    );
  }
}

/// Details pane: the focused record's properties, or a summary when several are selected.
class _PropertiesPanel extends ConsumerWidget {
  const _PropertiesPanel({this.onClose});

  /// Set when shown as an overlay; otherwise the button collapses the side pane.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final doc = ref.watch(selectedDocumentProvider);
    final ids = ref.watch(repositorySelectionProvider);
    final docs = ref.watch(repositoryDocumentsProvider).valueOrNull ?? const <DocumentRecord>[];
    final selected = docs.where((d) => ids.contains(d.id)).toList();
    final recycleBin = ref.watch(repositoryRecycleBinProvider);

    final header = Row(
      children: [
        Expanded(
          child: Text(
            'DETAILS',
            style: TextStyle(fontSize: 10.5, letterSpacing: 0.8, fontWeight: FontWeight.w700, color: tokens.ink3),
          ),
        ),
        IconButton(
          style: _compactIconStyle,
          tooltip: onClose != null ? 'Close' : 'Hide details pane',
          icon: Icon(onClose != null ? PhosphorIconsRegular.x : PhosphorIconsRegular.caretRight, size: 15, color: tokens.ink2),
          onPressed: onClose ?? () => ref.read(repositoryDetailsCollapsedProvider.notifier).state = true,
        ),
      ],
    );

    Widget kv(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(k, style: TextStyle(fontSize: 11.5, color: tokens.ink3)),
          ),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );

    Widget body;
    if (selected.length > 1) {
      final size = selected.fold<int>(0, (s, d) => s + (d.sizeBytes ?? 0));
      final pages = selected.fold<int>(0, (s, d) => s + (d.pageCount ?? 0));
      final byStatus = <String, int>{};
      final byType = <String, int>{};
      for (final d in selected) {
        byStatus[d.status] = (byStatus[d.status] ?? 0) + 1;
        byType[d.documentType ?? '—'] = (byType[d.documentType ?? '—'] ?? 0) + 1;
      }
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                color: tokens.accT,
                child: Icon(PhosphorIconsRegular.files, size: 18, color: tokens.accD),
              ),
              const SizedBox(width: 10),
              Text('${selected.length} items selected', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          kv('Total size', _formatSize(size)),
          kv('Pages', '$pages'),
          const SizedBox(height: 8),
          Text('Status', style: TextStyle(fontSize: 11.5, color: tokens.ink3)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final e in byStatus.entries) _CountChip(label: e.key.replaceAll('_', ' '), count: e.value)],
          ),
          const SizedBox(height: 10),
          Text('Types', style: TextStyle(fontSize: 11.5, color: tokens.ink3)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final e in byType.entries) _CountChip(label: e.key, count: e.value)],
          ),
          const SizedBox(height: 14),
          if (recycleBin)
            _PanelButton(icon: PhosphorIconsRegular.arrowCounterClockwise, label: 'Restore all', onTap: () => _restoreDocuments(context, ref, selected))
          else ...[
            _PanelButton(icon: PhosphorIconsRegular.folderSimpleDashed, label: 'Move to…', onTap: () => _pickFolderAndMove(context, ref, selected)),
            const SizedBox(height: 6),
            _PanelButton(icon: PhosphorIconsRegular.trash, label: 'Delete', danger: true, onTap: () => _deleteDocuments(context, ref, selected)),
          ],
        ],
      );
    } else if (doc == null) {
      body = const EmptyState(message: 'Select a record to see its details.');
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                color: tokens.accT,
                child: Icon(_iconForMime(doc.mimeType), size: 18, color: tokens.accD),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                    Text(doc.recordNo, style: TextStyle(fontSize: 11.5, color: tokens.accD)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StatusChip.forDocumentStatus(doc.status),
          const SizedBox(height: 10),
          kv('Type', doc.documentType ?? '—'),
          kv('Department', doc.department ?? '—'),
          kv('Custodian', doc.ownerName ?? '—'),
          kv('Version', doc.currentVersionNo != null ? 'v${doc.currentVersionNo}' : '—'),
          kv('Pages', doc.pagesLabel),
          kv('Size', doc.sizeBytes == null ? '—' : _formatSize(doc.sizeBytes!)),
          kv('Classification', doc.classification),
          kv('File plan', doc.folderPath ?? '—'),
          kv('Storage', doc.storageProvider != null ? storageProviderIconAndLabel(doc.storageProvider!).$2 : '—'),
          kv('Registered', _date(doc.createdAt)),
          const SizedBox(height: 12),
          _PanelButton(icon: PhosphorIconsRegular.arrowSquareOut, label: 'Open', primary: true, onTap: () => _openDocument(context, ref, doc)),
          if (!recycleBin) ...[
            const SizedBox(height: 6),
            _PanelButton(
              icon: PhosphorIconsRegular.clockCounterClockwise,
              label: 'Version history',
              onTap: () => context.go(RoutePaths.versionsFor('${doc.id}')),
            ),
            const SizedBox(height: 6),
            _PanelButton(icon: PhosphorIconsRegular.lockKey, label: 'Manage access', onTap: () => context.go('/permissions/document/${doc.id}')),
          ],
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.line),
        color: tokens.surf,
      ),
      padding: const EdgeInsets.fromLTRB(12, 4, 6, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(
            child: SingleChildScrollView(padding: const EdgeInsets.only(right: 6, top: 4), child: body),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: tokens.line),
        color: tokens.surf2,
      ),
      child: Text('$label · $count', style: const TextStyle(fontSize: 11)),
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({required this.icon, required this.label, required this.onTap, this.primary = false, this.danger = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = danger ? tokens.bad : (primary ? Colors.white : tokens.ink);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: primary ? tokens.acc : null,
          border: Border.all(color: primary ? tokens.acc : (danger ? tokens.bad.withValues(alpha: 0.5) : tokens.line2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: primary ? FontWeight.w600 : FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}
