import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/department_row.dart';
import '../../../core/models/document_record.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/result_dialog.dart';
import '../../../core/widgets/status_chip.dart';
import '../providers/repository_providers.dart';
import 'edit_document_dialog.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final title = Text(
                recycleBin ? 'Records / Repository / Recycle bin' : 'Records / Repository',
                style: Theme.of(context).textTheme.titleMedium,
              );
              final filterBar = _FilterBar();
              const viewToggle = _ViewModeToggle();
              const recycleToggle = _RecycleBinToggle();
              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [title, const Spacer(), recycleToggle, const SizedBox(width: 8), viewToggle]),
                    const SizedBox(height: 10),
                    filterBar,
                  ],
                );
              }
              return Row(
                children: [
                  title,
                  const Spacer(),
                  filterBar,
                  const SizedBox(width: 10),
                  recycleToggle,
                  const SizedBox(width: 8),
                  viewToggle,
                ],
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
                    data: (docs) => ref.watch(repositoryViewModeProvider) == RepositoryViewMode.grid
                        ? _DocumentGrid(docs: docs, recycleBin: recycleBin)
                        : _DocumentList(docs: docs, recycleBin: recycleBin),
                  ),
                ),
                if (showDetails) ...[
                  const SizedBox(width: 16),
                  detailsCollapsed
                      ? const _CollapsedDetailsTab()
                      : const SizedBox(width: 280, child: _PropertiesPanel()),
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
        style: active
            ? OutlinedButton.styleFrom(backgroundColor: tokens.sel, foregroundColor: tokens.ink)
            : null,
        icon: Icon(active ? Icons.arrow_back : Icons.delete_outline, size: 16),
        label: Text(active ? 'Back' : 'Recycle bin'),
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
          decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
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
            width: 32,
            height: 32,
            alignment: Alignment.center,
            color: selected ? tokens.sel : Colors.transparent,
            child: Icon(icon, size: 17, color: selected ? tokens.ink : tokens.ink2),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(RepositoryViewMode.list, Icons.view_list_outlined, 'List view'),
          Container(width: 1, height: 32, color: tokens.line),
          button(RepositoryViewMode.grid, Icons.grid_view_outlined, 'Grid view'),
        ],
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
        );

    if (folderId == null) {
      return InkWell(onTap: onTap, child: row());
    }

    return DragTarget<DocumentRecord>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => _moveDocument(context, ref, details.data, folderId: folderId!, folderLabel: label),
      builder: (context, candidateData, rejectedData) {
        return InkWell(onTap: onTap, child: row(hovering: candidateData.isNotEmpty));
      },
    );
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

  final result = await showDialog<
      ({
        String title,
        int documentTypeId,
        int folderId,
        int? departmentId,
        String classification,
        String? memberNumber,
        String? memberName,
      })>(
    context: context,
    builder: (_) => EditDocumentDialog(doc: doc, types: types, folders: folders, departments: departments),
  );
  if (result == null) return;

  try {
    await ref.read(documentsApiProvider).update(
          doc.id,
          title: result.title,
          documentTypeId: result.documentTypeId,
          folderId: result.folderId,
          departmentId: result.departmentId,
          classification: result.classification,
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
          icon: Icon(Icons.more_vert, size: 16, color: tokens.ink2),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (v) => v == 'edit' ? _editDocument(context, ref, doc) : _deleteDocument(context, ref, doc),
        ),
      ],
    );
  }
}

class _DocumentList extends ConsumerWidget {
  const _DocumentList({required this.docs, required this.recycleBin});

  final List<DocumentRecord> docs;
  final bool recycleBin;

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
                const SizedBox(width: 76),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i];
                final rowContent = Container(
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
                      SizedBox(width: 76, child: _DocumentActionsButton(doc: d, recycleBin: recycleBin)),
                    ],
                  ),
                );
                final tappable = InkWell(
                  onTap: () {
                    ref.read(selectedDocumentProvider.notifier).state = d;
                    context.go(RoutePaths.viewerFor('${d.id}'));
                  },
                  child: rowContent,
                );
                if (recycleBin) return tappable;
                return Draggable<DocumentRecord>(
                  data: d,
                  feedback: _DragFeedback(doc: d),
                  childWhenDragging: Opacity(opacity: 0.4, child: rowContent),
                  child: tappable,
                );
              },
            ),
          ),
        ],
      ),
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
        decoration: BoxDecoration(border: Border.all(color: tokens.accD), color: tokens.surf),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconForMime(doc.mimeType), size: 16, color: tokens.accD),
            const SizedBox(width: 6),
            Flexible(child: Text(doc.title, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class _DocumentGrid extends ConsumerWidget {
  const _DocumentGrid({required this.docs, required this.recycleBin});

  final List<DocumentRecord> docs;
  final bool recycleBin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (docs.isEmpty) {
      return const EmptyState(message: 'No records match. Try clearing the filters.');
    }
    final tokens = context.tokens;
    final selected = ref.watch(selectedDocumentProvider);

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: 172,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: docs.length,
      itemBuilder: (context, i) {
        final d = docs[i];
        final isSelected = selected?.id == d.id;
        final card = Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 4, 10),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? tokens.accD : tokens.line),
            color: isSelected ? tokens.sel : tokens.surf,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconForMime(d.mimeType), size: 30, color: tokens.accD),
                  const Spacer(),
                  _DocumentActionsButton(doc: d, recycleBin: recycleBin),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.title,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(d.recordNo, style: TextStyle(fontSize: 11, color: tokens.ink2)),
                  ],
                ),
              ),
              const Spacer(),
              Padding(padding: const EdgeInsets.only(left: 6), child: StatusChip.forDocumentStatus(d.status)),
            ],
          ),
        );
        final tappable = InkWell(
          onTap: () {
            ref.read(selectedDocumentProvider.notifier).state = d;
            context.go(RoutePaths.viewerFor('${d.id}'));
          },
          child: card,
        );
        if (recycleBin) return tappable;
        return Draggable<DocumentRecord>(
          data: d,
          feedback: _DragFeedback(doc: d),
          childWhenDragging: Opacity(opacity: 0.4, child: card),
          child: tappable,
        );
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
        tooltip: 'Hide properties',
        icon: Icon(Icons.chevron_right, size: 18, color: tokens.ink2),
        onPressed: () => ref.read(repositoryDetailsCollapsedProvider.notifier).state = true,
      ),
    );

    if (doc == null) {
      return Container(
        decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
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
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          collapseButton,
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
