import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/document_type_row.dart';
import '../../../core/models/folder_row.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/utils/mime_type.dart';
import '../../integrations/providers/integrations_providers.dart';
import '../../repository/providers/repository_providers.dart';
import '../providers/upload_batch_storage_provider.dart';
import '../providers/upload_queue_provider.dart';
import 'widgets/storage_location_dialog.dart';
import 'widgets/upload_file_preview.dart';

/// Whether dragging a file from the OS onto this screen should be
/// accepted — desktop_drop supports Windows fully and Android as a
/// (preview) multi-window/split-screen feature; gated to Windows and
/// tablet-width Android specifically, per the app's other wide-layout
/// breakpoint (login_screen.dart's `width >= 720`), rather than every
/// phone-sized Android window.
bool _dragAndDropEnabled(BuildContext context) {
  if (defaultTargetPlatform == TargetPlatform.windows) return true;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return MediaQuery.sizeOf(context).width >= 720;
  }
  return false;
}

final _draggingOverUploadProvider = StateProvider.autoDispose<bool>((ref) => false);

class SmartUploadScreen extends ConsumerWidget {
  const SmartUploadScreen({super.key});

  Future<void> _pickFiles(WidgetRef ref) async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) return;
    final files = [for (final f in picked) (bytes: await f.readAsBytes(), fileName: f.name, mimeType: mimeTypeForExtension(extensionOf(f.name)))];
    ref.read(uploadQueueProvider.notifier).addFiles(files);
  }

  Future<void> _handleDroppedFiles(WidgetRef ref, List<DropItem> items) async {
    // DropItemDirectory (a dropped folder) has no bytes of its own to read —
    // only individual files are meaningful uploads here.
    final droppedFiles = items.whereType<DropItem>().where((i) => i is! DropItemDirectory);
    final files = [for (final f in droppedFiles) (bytes: await f.readAsBytes(), fileName: f.name, mimeType: mimeTypeForExtension(extensionOf(f.name)))];
    if (files.isNotEmpty) ref.read(uploadQueueProvider.notifier).addFiles(files);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final rows = ref.watch(uploadQueueProvider);
    final types = ref.watch(documentTypesProvider).valueOrNull ?? const <DocumentTypeRow>[];
    final foldersAsync = ref.watch(foldersProvider);
    final folders = [...(foldersAsync.valueOrNull ?? const <FolderRow>[])]..sort((a, b) => a.path.compareTo(b.path));
    final dragAndDropEnabled = _dragAndDropEnabled(context);
    final draggingOver = dragAndDropEnabled && ref.watch(_draggingOverUploadProvider);

    final ready = rows.where((r) => r.isReady).length;
    final registered = rows.where((r) => r.status == UploadRowStatus.committed).length;
    // Only an in-flight registration blocks the button; files still being read just aren't counted as ready.
    final busy = rows.any((r) => r.status == UploadRowStatus.committing);
    final incomplete = rows.where((r) => !r.isReady && !r.isBusy && r.status != UploadRowStatus.committed).length;

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smart Upload', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      'Add files, check the suggestions, register. Type and record number are filled in for you.',
                      style: TextStyle(fontSize: 11.5, color: tokens.ink3),
                    ),
                  ],
                ),
              ),
              const _StorageLocationSummary(),
              const SizedBox(width: 8),
              ElevatedButton.icon(onPressed: () => _pickFiles(ref), icon: const Icon(Icons.add, size: 16), label: const Text('Add files')),
            ],
          ),
          const SizedBox(height: 12),
          _DefaultsBar(types: types, folders: folders, hasRows: rows.isNotEmpty),
          const SizedBox(height: 10),
          Expanded(
            child: rows.isEmpty
                ? _EmptyDropZone(dragAndDrop: dragAndDropEnabled, onBrowse: () => _pickFiles(ref))
                : Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: tokens.line),
                      color: tokens.surf,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _QueueHeader(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: rows.length,
                            itemBuilder: (context, i) =>
                                _UploadRowTile(key: ValueKey(rows[i].localId), row: rows[i], allRows: rows, types: types, folders: folders),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text('${rows.length} file${rows.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                _dot(tokens),
                Text('$ready ready', style: TextStyle(fontSize: 12.5, color: ready > 0 ? tokens.ok : tokens.ink2)),
                if (incomplete > 0) ...[_dot(tokens), Text('$incomplete need details', style: TextStyle(fontSize: 12.5, color: tokens.warn))],
                if (registered > 0) ...[
                  _dot(tokens),
                  Text('$registered registered', style: TextStyle(fontSize: 12.5, color: tokens.ink2)),
                  TextButton(
                    onPressed: () => context.go(RoutePaths.repository),
                    child: const Text('Open Repository', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () => ref.read(uploadQueueProvider.notifier).clearRegistered(),
                    child: const Text('Clear registered', style: TextStyle(fontSize: 12)),
                  ),
                ],
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: ready == 0 || busy || !foldersAsync.hasValue ? null : () => ref.read(uploadQueueProvider.notifier).commitAll(foldersAsync.value!),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(ready == 0 ? 'Register' : 'Register $ready file${ready == 1 ? '' : 's'}'),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (!dragAndDropEnabled) return body;

    return DropTarget(
      onDragEntered: (_) => ref.read(_draggingOverUploadProvider.notifier).state = true,
      onDragExited: (_) => ref.read(_draggingOverUploadProvider.notifier).state = false,
      onDragDone: (details) {
        ref.read(_draggingOverUploadProvider.notifier).state = false;
        _handleDroppedFiles(ref, details.files);
      },
      child: Stack(
        children: [
          body,
          if (draggingOver)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tokens.acc.withValues(alpha: 0.12),
                    border: Border.all(color: tokens.accD, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Drop to add files',
                    style: TextStyle(color: tokens.accD, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _dot(PspfTokens tokens) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Text('·', style: TextStyle(color: tokens.ink3)),
  );
}

class _EmptyDropZone extends StatelessWidget {
  const _EmptyDropZone({required this.dragAndDrop, required this.onBrowse});

  final bool dragAndDrop;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: onBrowse,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surf,
          border: Border.all(color: tokens.line2, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file_outlined, size: 34, color: tokens.accD),
            const SizedBox(height: 10),
            Text(
              dragAndDrop ? 'Drop files here, or click to browse' : 'Click to choose files',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text('Each file is read, its type suggested and a record number assigned automatically.', style: TextStyle(fontSize: 12, color: tokens.ink2)),
          ],
        ),
      ),
    );
  }
}

/// Batch-wide folder / type / classification. New files take these;
/// "Apply to all" pushes them onto files already in the list.
class _DefaultsBar extends ConsumerWidget {
  const _DefaultsBar({required this.types, required this.folders, required this.hasRows});

  final List<DocumentTypeRow> types;
  final List<FolderRow> folders;
  final bool hasRows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final d = ref.watch(uploadDefaultsProvider);
    void set(UploadDefaults next) {
      ref.read(uploadDefaultsProvider.notifier).state = next;
      // Fill any empty fields right away; overwriting is the explicit button.
      ref.read(uploadQueueProvider.notifier).applyDefaults();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: tokens.surf2,
        border: Border.all(color: tokens.line),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'FOR ALL FILES',
            style: TextStyle(fontSize: 10.5, letterSpacing: 0.6, fontWeight: FontWeight.w700, color: tokens.ink2),
          ),
          SizedBox(
            width: 250,
            child: _CompactSelect<int?>(
              label: 'Folder',
              value: d.folderId,
              hint: 'Choose a folder',
              items: [for (final f in folders) (f.id, f.path)],
              onChanged: (v) => set(UploadDefaults(folderId: v, documentTypeId: d.documentTypeId, classification: d.classification)),
            ),
          ),
          SizedBox(
            width: 220,
            child: _CompactSelect<int?>(
              label: 'Type',
              value: d.documentTypeId,
              items: [(null, 'Detect for each file'), for (final t in types) (t.id, t.name)],
              onChanged: (v) => set(UploadDefaults(folderId: d.folderId, documentTypeId: v, classification: d.classification)),
            ),
          ),
          SizedBox(
            width: 170,
            child: _CompactSelect<String>(
              label: 'Access',
              value: d.classification,
              items: const [('public', 'Public'), ('internal', 'Internal'), ('restricted', 'Restricted'), ('confidential', 'Confidential')],
              onChanged: (v) => set(UploadDefaults(folderId: d.folderId, documentTypeId: d.documentTypeId, classification: v ?? 'internal')),
            ),
          ),
          if (hasRows)
            TextButton(
              onPressed: () => ref.read(uploadQueueProvider.notifier).applyDefaults(overwrite: true),
              child: const Text('Apply to every file', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

/// A 30px bordered dropdown with a small inline label — keeps rows dense.
class _CompactSelect<T> extends StatelessWidget {
  const _CompactSelect({required this.value, required this.items, required this.onChanged, this.label, this.hint, this.error = false});

  final T value;
  final List<(T, String)> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;

  /// Highlights a required field that is still empty.
  final bool error;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasValue = items.any((i) => i.$1 == value);
    return Container(
      height: 30,
      padding: const EdgeInsets.only(left: 8, right: 4),
      decoration: BoxDecoration(
        color: onChanged == null ? tokens.surf2 : tokens.surf,
        border: Border.all(color: error ? tokens.warn : tokens.line2),
      ),
      child: Row(
        children: [
          if (label != null) ...[Text(label!, style: TextStyle(fontSize: 11, color: tokens.ink3)), const SizedBox(width: 6)],
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: hasValue ? value : null,
                isExpanded: true,
                isDense: true,
                iconSize: 18,
                hint: Text(hint ?? 'Choose…', style: TextStyle(fontSize: 12, color: error ? tokens.warn : tokens.ink3)),
                style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(fontSize: 12, color: tokens.ink),
                items: [
                  for (final (v, text) in items)
                    DropdownMenuItem<T>(
                      value: v,
                      child: Text(text, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _kColFile = 5;
const _kColType = 3;
const _kColIndex = 3;
const _kColFolder = 4;
const _kStatusWidth = 150.0;

class _QueueHeader extends StatelessWidget {
  const _QueueHeader();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    Widget h(String t, int flex) => Expanded(
      flex: flex,
      child: Text(
        t.toUpperCase(),
        style: TextStyle(fontSize: 10.5, letterSpacing: 0.5, fontWeight: FontWeight.w700, color: tokens.ink2),
      ),
    );
    return Container(
      color: tokens.surf2,
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      child: Row(
        children: [
          h('File', _kColFile),
          const SizedBox(width: 8),
          h('Type', _kColType),
          const SizedBox(width: 8),
          h('Record no.', _kColIndex),
          const SizedBox(width: 8),
          h('Folder', _kColFolder),
          const SizedBox(width: 8),
          SizedBox(
            width: _kStatusWidth,
            child: Text('STATUS', style: TextStyle(fontSize: 10.5, letterSpacing: 0.5, fontWeight: FontWeight.w700, color: tokens.ink2)),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }
}

/// One file: a single aligned line; the rarely-needed fields fold out below.
class _UploadRowTile extends ConsumerStatefulWidget {
  const _UploadRowTile({super.key, required this.row, required this.allRows, required this.types, required this.folders});

  final UploadRow row;
  final List<UploadRow> allRows;
  final List<DocumentTypeRow> types;
  final List<FolderRow> folders;

  @override
  ConsumerState<_UploadRowTile> createState() => _UploadRowTileState();
}

class _UploadRowTileState extends ConsumerState<_UploadRowTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final row = widget.row;
    final notifier = ref.read(uploadQueueProvider.notifier);
    final locked = row.status == UploadRowStatus.committed || row.isBusy;
    final recognised = row.status != UploadRowStatus.queued && row.status != UploadRowStatus.recognizing;

    final line = Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Row(
        children: [
          Expanded(
            flex: _kColFile,
            child: Row(
              children: [
                UploadFilePreviewThumb(
                  bytes: row.bytes,
                  fileName: row.fileName,
                  mimeType: row.mimeType,
                  extractedText: row.extractedText,
                  extractedTextLoading: row.status == UploadRowStatus.recognizing,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.title.isEmpty ? row.fileName : row.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        row.recordNo != null ? '${row.fileName} → ${row.recordNo}' : row.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: tokens.ink3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: _kColType,
            child: _CompactSelect<int?>(
              value: row.documentTypeId,
              hint: recognised ? 'Choose type' : 'Detecting…',
              error: recognised && row.documentTypeId == null,
              items: [for (final t in widget.types) (t.id, t.name)],
              onChanged: locked ? null : (v) => notifier.updateField(row.localId, documentTypeId: () => v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: _kColIndex,
            child: _IndexSelect(row: row, allRows: widget.allRows, locked: locked),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: _kColFolder,
            child: _CompactSelect<int?>(
              value: row.folderId,
              hint: 'Choose folder',
              error: recognised && row.folderId == null,
              items: [for (final f in widget.folders) (f.id, f.path)],
              onChanged: locked ? null : (v) => notifier.updateField(row.localId, folderId: () => v),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: _kStatusWidth,
            child: _RowStatus(row: row),
          ),
          IconButton(
            tooltip: _expanded ? 'Hide details' : 'More details',
            visualDensity: VisualDensity.compact,
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: tokens.ink2),
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
          IconButton(
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: 16, color: tokens.ink3),
            onPressed: row.isBusy ? null : () => notifier.removeRow(row.localId),
          ),
        ],
      ),
    );

    final duplicate = row.duplicateOf != null && row.status != UploadRowStatus.committed;
    return Container(
      decoration: BoxDecoration(
        color: row.status == UploadRowStatus.committed ? tokens.ok.withValues(alpha: 0.05) : null,
        border: Border(bottom: BorderSide(color: tokens.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line,
          if (duplicate)
            Container(
              margin: const EdgeInsets.fromLTRB(56, 0, 10, 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: tokens.warn.withValues(alpha: 0.08),
                border: Border(left: BorderSide(color: tokens.warn, width: 3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Same content as ${row.duplicateOf!.recordNo} (${row.duplicateOf!.title}).',
                      style: TextStyle(fontSize: 11.5, color: tokens.ink),
                    ),
                  ),
                  Checkbox(
                    value: row.allowDuplicate,
                    visualDensity: VisualDensity.compact,
                    onChanged: (v) => notifier.setAllowDuplicate(row.localId, v ?? false),
                  ),
                  const Text('Register anyway', style: TextStyle(fontSize: 11.5)),
                ],
              ),
            ),
          if (_expanded)
            Container(
              margin: const EdgeInsets.fromLTRB(56, 0, 10, 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tokens.surf2,
                border: Border.all(color: tokens.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: 280,
                        child: _InlineText(
                          label: 'Title',
                          initial: row.title,
                          enabled: !locked,
                          onChanged: (v) => notifier.updateField(row.localId, title: v),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: _InlineText(
                          label: 'Member / employer no.',
                          initial: row.memberNumber,
                          enabled: !locked,
                          onChanged: (v) => notifier.updateField(row.localId, memberNumber: v),
                        ),
                      ),
                      SizedBox(
                        width: 190,
                        child: _CompactSelect<String>(
                          label: 'Access',
                          value: row.classification,
                          items: const [('public', 'Public'), ('internal', 'Internal'), ('restricted', 'Restricted'), ('confidential', 'Confidential')],
                          onChanged: locked ? null : (v) => notifier.updateField(row.localId, classification: v),
                        ),
                      ),
                      if (row.confidence != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Text recognised with ${row.confidence}% confidence', style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _CustomFieldsSection(row: row),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InlineText extends StatelessWidget {
  const _InlineText({required this.label, required this.initial, required this.enabled, required this.onChanged});

  final String label;
  final String initial;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      height: 30,
      child: TextFormField(
        initialValue: initial,
        enabled: enabled,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: tokens.surf,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          prefixText: '$label  ',
          prefixStyle: TextStyle(fontSize: 11, color: tokens.ink3),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: tokens.line2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: tokens.accD),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: tokens.line),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Record-number picker: the available numbers for the row's type, minus
/// ones other files in this batch already hold. Pre-filled automatically.
class _IndexSelect extends ConsumerWidget {
  const _IndexSelect({required this.row, required this.allRows, required this.locked});

  final UploadRow row;
  final List<UploadRow> allRows;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    if (row.status == UploadRowStatus.committed) {
      return Text(
        row.recordNo ?? '—',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.accD),
      );
    }
    if (row.documentTypeId == null) {
      return _CompactSelect<int?>(value: null, hint: 'Pick a type first', items: const [], onChanged: null);
    }
    final indexesAsync = ref.watch(availableRecordIndexesProvider(row.documentTypeId!));
    final pickedByOthers = {
      for (final r in allRows)
        if (r.localId != row.localId && r.recordIndexId != null) r.recordIndexId!,
    };
    return indexesAsync.when(
      loading: () => _CompactSelect<int?>(value: null, hint: 'Loading…', items: const [], onChanged: null),
      error: (e, _) => Text('Couldn\'t load record numbers', style: TextStyle(color: tokens.bad, fontSize: 11.5)),
      data: (indexes) {
        final options = indexes.where((idx) => idx.id == row.recordIndexId || !pickedByOthers.contains(idx.id)).toList();
        if (options.isEmpty) {
          return Tooltip(
            message: 'Generate or add record numbers for this type in Settings → Indexing.',
            child: Container(
              height: 30,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(border: Border.all(color: tokens.warn)),
              child: Text('None left for this type', style: TextStyle(fontSize: 11.5, color: tokens.warn)),
            ),
          );
        }
        return _CompactSelect<int?>(
          value: row.recordIndexId,
          hint: 'Choose number',
          error: row.recordIndexId == null,
          items: [for (final idx in options) (idx.id, idx.indexValue)],
          onChanged: locked ? null : (v) => ref.read(uploadQueueProvider.notifier).setRecordIndex(row.localId, v),
        );
      },
    );
  }
}

class _RowStatus extends StatelessWidget {
  const _RowStatus({required this.row});

  final UploadRow row;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    Widget spinner(String text) => Row(
      children: [
        SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: tokens.acc)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
      ],
    );
    Widget label(IconData icon, String text, Color color) => Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: color),
          ),
        ),
      ],
    );

    switch (row.status) {
      case UploadRowStatus.queued:
        return Text('Queued', style: TextStyle(fontSize: 11.5, color: tokens.ink2));
      case UploadRowStatus.recognizing:
        return spinner('Reading file…');
      case UploadRowStatus.committing:
        return spinner('Registering…');
      case UploadRowStatus.committed:
        return label(Icons.check_circle, 'Registered', tokens.ok);
      case UploadRowStatus.recognitionFailed:
      case UploadRowStatus.commitFailed:
        return Tooltip(message: row.error ?? 'Failed', child: label(Icons.error_outline, row.error ?? 'Failed', tokens.bad));
      case UploadRowStatus.recognized:
        final missing = row.missing;
        return missing.isEmpty ? label(Icons.check, 'Ready', tokens.ok) : label(Icons.info_outline, 'Needs ${missing.join(', ')}', tokens.warn);
    }
  }
}

/// Optional label:value tags — "custom indexing" beyond the fixed
/// type/folder/member fields, collapsed to a compact chip row plus an
/// "+ Add" affordance for adding another.
class _CustomFieldsSection extends ConsumerStatefulWidget {
  const _CustomFieldsSection({required this.row});

  final UploadRow row;

  @override
  ConsumerState<_CustomFieldsSection> createState() => _CustomFieldsSectionState();
}

class _CustomFieldsSectionState extends ConsumerState<_CustomFieldsSection> {
  bool _adding = false;
  final _labelController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _add() {
    ref.read(uploadQueueProvider.notifier).addCustomField(widget.row.localId, _labelController.text, _valueController.text);
    _labelController.clear();
    _valueController.clear();
    setState(() => _adding = false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final readOnly = widget.row.status == UploadRowStatus.committed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Custom fields:', style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
            for (var i = 0; i < widget.row.customFields.length; i++)
              Chip(
                label: Text('${widget.row.customFields[i].label}: ${widget.row.customFields[i].value}', style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                onDeleted: readOnly ? null : () => ref.read(uploadQueueProvider.notifier).removeCustomField(widget.row.localId, i),
              ),
            if (!readOnly && !_adding)
              TextButton(
                onPressed: () => setState(() => _adding = true),
                child: const Text('+ Add', style: TextStyle(fontSize: 11.5)),
              ),
          ],
        ),
        if (_adding) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _labelController,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Label', isDense: true),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: _valueController,
                  decoration: const InputDecoration(hintText: 'Value', isDense: true),
                  onSubmitted: (_) => _add(),
                ),
              ),
              IconButton(icon: const Icon(Icons.check, size: 18), onPressed: _add),
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _adding = false)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Batch-level storage-location summary + override entry point, shown above
/// the file list. Defaults to whichever provider is currently the global
/// active one, with per-file folders otherwise derived automatically.
class _StorageLocationSummary extends ConsumerWidget {
  const _StorageLocationSummary();

  Future<void> _change(BuildContext context, WidgetRef ref, String defaultProviderId) async {
    final storageIntegrations = ref.read(storageOptionsProvider).valueOrNull ?? const [];
    if (storageIntegrations.isEmpty) return;

    final current = ref.read(uploadBatchStorageProvider);
    final result = await StorageLocationDialog.show(
      context,
      storageIntegrations: storageIntegrations,
      initialProviderId: current.providerId ?? defaultProviderId,
      initialPrefix: current.prefixOverride,
    );
    if (result != null) {
      ref.read(uploadBatchStorageProvider.notifier).setLocation(providerId: result.providerId, prefixOverride: result.prefixOverride);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final activeAsync = ref.watch(storageLocationProvider);
    final batch = ref.watch(uploadBatchStorageProvider);
    ref.watch(storageOptionsProvider); // kick off the fetch early so it's ready by the time "Change" is tapped

    return activeAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (active) {
        final effectiveProvider = batch.providerId ?? active;
        final folderDescription = batch.prefixOverride == null || batch.prefixOverride!.isEmpty
            ? "Files are stored under each file's Repository folder."
            : 'Stored under "${batch.prefixOverride}".';
        return Tooltip(
          message: folderDescription,
          child: InkWell(
            onTap: () => _change(context, ref, active),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(border: Border.all(color: tokens.line2)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_outlined, size: 15, color: tokens.ink2),
                  const SizedBox(width: 6),
                  Text('Storage: $effectiveProvider', style: TextStyle(fontSize: 12, color: tokens.ink)),
                  const SizedBox(width: 6),
                  Text(
                    'Change',
                    style: TextStyle(fontSize: 12, color: tokens.accD, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
