import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/document_type_row.dart';
import '../../../core/models/folder_row.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/utils/mime_type.dart';
import '../../../core/widgets/status_chip.dart';
import '../../integrations/providers/integrations_providers.dart';
import '../../repository/providers/repository_providers.dart';
import '../providers/upload_batch_storage_provider.dart';
import '../providers/upload_queue_provider.dart';
import 'widgets/create_folder_dialog.dart';
import 'widgets/storage_location_dialog.dart';
import 'widgets/upload_file_preview.dart';

class SmartUploadScreen extends ConsumerWidget {
  const SmartUploadScreen({super.key});

  Future<void> _pickFiles(WidgetRef ref) async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) return;
    final files = [
      for (final f in picked)
        (bytes: await f.readAsBytes(), fileName: f.name, mimeType: mimeTypeForExtension(extensionOf(f.name))),
    ];
    ref.read(uploadQueueProvider.notifier).addFiles(files);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final rows = ref.watch(uploadQueueProvider);
    final typesAsync = ref.watch(documentTypesProvider);
    final foldersAsync = ref.watch(foldersProvider);
    final needAttention = rows.where((r) => r.needsAttention).length;
    final allCommitted = rows.isNotEmpty && rows.every((r) => r.status == UploadRowStatus.committed);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Records / Smart Upload — recognise & index', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _pickFiles(ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add files'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: rows.isEmpty || !typesAsync.hasValue || !foldersAsync.hasValue
                    ? null
                    : () => ref.read(uploadQueueProvider.notifier).commitAll(typesAsync.value!, foldersAsync.value!),
                child: const Text('Index & register all'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Recognition, classification and indexing run on upload — no scanner required. '
            'Suggested type/member number come from simple keyword matching on the extracted text, not AI.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens.ink2),
          ),
          const SizedBox(height: 10),
          const _StorageLocationSummary(),
          if (needAttention > 0) ...[
            const SizedBox(height: 8),
            Text('$needAttention file(s) need attention.', style: TextStyle(color: tokens.warn, fontSize: 12)),
          ],
          if (allCommitted) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: tokens.ok),
                const SizedBox(width: 6),
                Text('All files registered.', style: TextStyle(color: tokens.ok, fontSize: 12.5)),
                const SizedBox(width: 12),
                TextButton(onPressed: () => context.go(RoutePaths.repository), child: const Text('Go to Repository')),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text('No files queued. Click "Add files" to begin.', style: TextStyle(color: tokens.ink2)),
                  )
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _UploadRowCard(
                      row: rows[i],
                      types: typesAsync.valueOrNull ?? const [],
                      folders: foldersAsync.valueOrNull ?? const [],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _UploadRowCard extends ConsumerWidget {
  const _UploadRowCard({required this.row, required this.types, required this.folders});

  final UploadRow row;
  final List<DocumentTypeRow> types;
  final List<FolderRow> folders;

  Future<void> _createFolder(BuildContext context, WidgetRef ref, String localId, List<FolderRow> folders) async {
    final result = await CreateFolderDialog.show(context, folders: folders);
    if (result == null) return;
    try {
      final created = await ref.read(foldersApiProvider).create(name: result.name, parentId: result.parentId);
      ref.invalidate(foldersProvider);
      ref.read(uploadQueueProvider.notifier).updateField(localId, folderId: () => created.id);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final notifier = ref.read(uploadQueueProvider.notifier);

    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UploadFilePreviewThumb(
                bytes: row.bytes,
                fileName: row.fileName,
                mimeType: row.mimeType,
                extractedText: row.extractedText,
                extractedTextLoading: row.status == UploadRowStatus.recognizing,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(row.fileName, style: textTheme.titleSmall, overflow: TextOverflow.ellipsis),
              ),
              _statusIndicator(tokens),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Remove',
                onPressed: () => notifier.removeRow(row.localId),
              ),
            ],
          ),
          if (row.status == UploadRowStatus.recognitionFailed || row.status == UploadRowStatus.commitFailed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(row.error ?? 'Failed', style: TextStyle(color: tokens.bad, fontSize: 11.5)),
            ),
          if (row.status != UploadRowStatus.queued && row.status != UploadRowStatus.recognizing) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    initialValue: row.title,
                    enabled: row.status != UploadRowStatus.committed,
                    decoration: const InputDecoration(labelText: 'Title', isDense: true),
                    onChanged: (v) => notifier.updateField(row.localId, title: v),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<int>(
                    initialValue: row.documentTypeId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Detected type', isDense: true),
                    items: [
                      for (final t in types) DropdownMenuItem(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: row.status == UploadRowStatus.committed
                        ? null
                        : (v) => notifier.updateField(row.localId, documentTypeId: () => v),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: row.folderId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Destination folder', isDense: true),
                          items: [
                            for (final f in folders) DropdownMenuItem(value: f.id, child: Text(f.path, overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: row.status == UploadRowStatus.committed
                              ? null
                              : (v) => notifier.updateField(row.localId, folderId: () => v),
                        ),
                      ),
                      if (row.status != UploadRowStatus.committed)
                        IconButton(
                          icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                          tooltip: 'New folder',
                          onPressed: () => _createFolder(context, ref, row.localId, folders),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextFormField(
                    initialValue: row.memberNumber,
                    enabled: row.status != UploadRowStatus.committed,
                    decoration: const InputDecoration(labelText: 'Member / employer', isDense: true),
                    onChanged: (v) => notifier.updateField(row.localId, memberNumber: v),
                  ),
                ),
                if (row.confidence != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StatusChip(
                      '${row.confidence}% confidence',
                      tone: row.confidence! >= 90 ? StatusTone.ok : (row.confidence! >= 70 ? StatusTone.warn : StatusTone.bad),
                    ),
                  ),
                if (row.recordNo != null)
                  Align(alignment: Alignment.centerLeft, child: StatusChip(row.recordNo!, tone: StatusTone.info)),
              ],
            ),
            if (row.duplicateOf != null && row.status != UploadRowStatus.committed) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(border: Border.all(color: tokens.warn), color: tokens.warn.withValues(alpha: 0.08)),
                child: Row(
                  children: [
                    Icon(Icons.content_copy, size: 16, color: tokens.warn),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This file\'s content matches an existing record: ${row.duplicateOf!.recordNo} (${row.duplicateOf!.title}).',
                        style: TextStyle(fontSize: 11.5, color: tokens.warn),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: row.allowDuplicate,
                          onChanged: (v) => notifier.setAllowDuplicate(row.localId, v ?? false),
                        ),
                        const Text('Upload anyway', style: TextStyle(fontSize: 11.5)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            _CustomFieldsSection(row: row),
          ],
        ],
      ),
    );
  }

  Widget _statusIndicator(PspfTokens tokens) {
    switch (row.status) {
      case UploadRowStatus.queued:
        return Text('Queued', style: TextStyle(fontSize: 11.5, color: tokens.ink2));
      case UploadRowStatus.recognizing:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: tokens.acc)),
            const SizedBox(width: 6),
            Text('Recognising…', style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
          ],
        );
      case UploadRowStatus.recognized:
        return StatusChip('Recognised', tone: StatusTone.info);
      case UploadRowStatus.recognitionFailed:
        return StatusChip('Recognition failed', tone: StatusTone.bad);
      case UploadRowStatus.committing:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: tokens.acc)),
            const SizedBox(width: 6),
            Text('Registering…', style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
          ],
        );
      case UploadRowStatus.committed:
        return StatusChip('Registered', tone: StatusTone.ok);
      case UploadRowStatus.commitFailed:
        return StatusChip('Failed', tone: StatusTone.bad);
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
            ? 'folder derived from each file\'s destination folder'
            : 'folder: ${batch.prefixOverride}';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf2),
          child: Row(
            children: [
              Icon(Icons.cloud_outlined, size: 15, color: tokens.ink2),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Storage location: $effectiveProvider — $folderDescription',
                  style: TextStyle(fontSize: 12, color: tokens.ink2),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(onPressed: () => _change(context, ref, active), child: const Text('Change', style: TextStyle(fontSize: 12))),
            ],
          ),
        );
      },
    );
  }
}
