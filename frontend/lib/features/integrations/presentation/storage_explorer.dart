import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/resources/integrations_api.dart';
import '../../../core/models/document_type_row.dart';
import '../../../core/models/folder_row.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/result_dialog.dart';
import '../../repository/providers/repository_providers.dart';
import 'import_from_storage_dialog.dart';

/// Inline, Explorer-like view of what is inside a storage location, with
/// what's already in the Repository marked, and "Register" to bring an
/// existing folder (and its subfolders) into the Repository.
class StorageExplorer extends ConsumerStatefulWidget {
  const StorageExplorer({super.key, required this.integrationId, required this.integrationName});

  final String integrationId;
  final String integrationName;

  @override
  ConsumerState<StorageExplorer> createState() => _StorageExplorerState();
}

class _StorageExplorerState extends ConsumerState<StorageExplorer> {
  String _prefix = '';
  StorageListing? _listing;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StorageExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.integrationId != widget.integrationId) {
      _prefix = '';
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listing = await ref.read(integrationsApiProvider).browseDetailed(widget.integrationId, prefix: _prefix);
      if (mounted) setState(() => _listing = listing);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(String folder) {
    _prefix = _prefix.isEmpty ? folder : '$_prefix/$folder';
    _load();
  }

  void _goTo(int depth) {
    final parts = _prefix.split('/').where((p) => p.isNotEmpty).toList();
    _prefix = parts.take(depth).join('/');
    _load();
  }

  Future<void> _newFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Folder name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(integrationsApiProvider).createFolder(widget.integrationId, prefix: _prefix.isEmpty ? null : _prefix, name: name);
      await _load();
    } on ApiException catch (e) {
      if (mounted) await ResultDialog.showError(context, e.message);
    }
  }

  Future<void> _importHere() async {
    final result = await showDialog<({int importedCount, int skippedCount})>(
      context: context,
      builder: (_) => ImportFromStorageDialog(integrationId: widget.integrationId, integrationName: widget.integrationName, prefix: _prefix),
    );
    if (result == null || !mounted) return;
    ref.invalidate(repositoryDocumentsProvider);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${result.importedCount} file(s), skipped ${result.skippedCount}.')));
    }
  }

  Future<void> _register(String prefix) async {
    final registered = await showDialog<bool>(
      context: context,
      builder: (_) => _RegisterFolderDialog(integrationId: widget.integrationId, prefix: prefix),
    );
    if (registered == true) {
      ref.invalidate(foldersProvider);
      ref.invalidate(repositoryDocumentsProvider);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final listing = _listing;
    final parts = _prefix.split('/').where((p) => p.isNotEmpty).toList();

    Widget toolButton(IconData icon, String label, VoidCallback? onTap) => TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: tokens.ink,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.line),
        color: tokens.surf,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Address bar + actions, like Explorer.
          Container(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
            decoration: BoxDecoration(
              color: tokens.surf2,
              border: Border(bottom: BorderSide(color: tokens.line)),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Up',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(PhosphorIconsRegular.arrowUp, size: 15, color: parts.isEmpty ? tokens.ink3 : tokens.ink),
                  onPressed: parts.isEmpty ? null : () => _goTo(parts.length - 1),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => _goTo(0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Text(widget.integrationName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        for (var i = 0; i < parts.length; i++) ...[
                          Icon(PhosphorIconsRegular.caretRight, size: 11, color: tokens.ink3),
                          InkWell(
                            onTap: () => _goTo(i + 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Text(parts[i], style: const TextStyle(fontSize: 12.5)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_prefix.isNotEmpty && listing?.currentFolderPath == null)
                  toolButton(PhosphorIconsRegular.folderPlus, 'Register this folder', () => _register(_prefix)),
                if (_prefix.isNotEmpty && listing?.currentFolderPath != null) toolButton(PhosphorIconsRegular.downloadSimple, 'Import new files', _importHere),
                toolButton(PhosphorIconsRegular.folderSimplePlus, 'New folder', _newFolder),
                IconButton(
                  tooltip: 'Refresh',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(PhosphorIconsRegular.arrowClockwise, size: 15, color: tokens.ink2),
                  onPressed: _load,
                ),
              ],
            ),
          ),
          if (listing?.currentFolderPath != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: tokens.ok.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.checkCircle, size: 14, color: tokens.ok),
                  const SizedBox(width: 6),
                  Text('Registered in the Repository as "${listing!.currentFolderPath}"', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _error != null
                ? Center(
                    child: Text(_error!, style: TextStyle(color: tokens.bad, fontSize: 12.5)),
                  )
                : listing == null
                ? const SizedBox.shrink()
                : (listing.folders.isEmpty && listing.files.isEmpty)
                ? Center(
                    child: Text('This folder is empty.', style: TextStyle(fontSize: 12.5, color: tokens.ink2)),
                  )
                : ListView(
                    children: [
                      for (final folder in listing.folders)
                        _EntryRow(
                          icon: PhosphorIconsDuotone.folder,
                          name: folder,
                          badge: listing.systemFolders.contains(folder)
                              ? ('EDMS system', tokens.ink3)
                              : listing.registeredFolders.containsKey(folder)
                              ? ('In Repository · ${listing.registeredFolders[folder]}', tokens.ok)
                              : null,
                          onOpen: () => _open(folder),
                          action: listing.systemFolders.contains(folder) || listing.registeredFolders.containsKey(folder)
                              ? null
                              : ('Register', () => _register(_prefix.isEmpty ? folder : '$_prefix/$folder')),
                        ),
                      for (final file in listing.files)
                        _EntryRow(
                          icon: PhosphorIconsRegular.file,
                          name: file,
                          badge: listing.registeredFiles.containsKey(file) ? (listing.registeredFiles[file]!, tokens.ok) : ('Not in Repository', tokens.ink3),
                        ),
                    ],
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: tokens.surf2,
              border: Border(top: BorderSide(color: tokens.line)),
            ),
            child: Text(
              listing == null
                  ? ' '
                  : '${listing.folders.length} folder(s) · ${listing.files.length} file(s) · ${listing.registeredFiles.length} already in the Repository',
              style: TextStyle(fontSize: 11, color: tokens.ink2),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.icon, required this.name, this.badge, this.onOpen, this.action});

  final IconData icon;
  final String name;
  final (String, Color)? badge;
  final VoidCallback? onOpen;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onDoubleTap: onOpen,
      onTap: onOpen,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: tokens.line)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: onOpen != null ? tokens.accD : tokens.ink3),
            const SizedBox(width: 9),
            Expanded(
              child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
            ),
            if (badge != null)
              Container(
                constraints: const BoxConstraints(maxWidth: 240),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(border: Border.all(color: badge!.$2.withValues(alpha: 0.5))),
                child: Text(
                  badge!.$1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: badge!.$2),
                ),
              ),
            if (action != null) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: action!.$2,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 24),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(action!.$1, style: const TextStyle(fontSize: 11.5)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Options for registering a storage folder: where it goes in the File Plan,
/// whether subfolders come too, and the document type (auto by default).
class _RegisterFolderDialog extends ConsumerStatefulWidget {
  const _RegisterFolderDialog({required this.integrationId, required this.prefix});

  final String integrationId;
  final String prefix;

  @override
  ConsumerState<_RegisterFolderDialog> createState() => _RegisterFolderDialogState();
}

class _RegisterFolderDialogState extends ConsumerState<_RegisterFolderDialog> {
  List<FolderRow> _folders = const [];
  List<DocumentTypeRow> _types = const [];
  int? _parentId;
  int? _typeId;
  bool _recursive = true;
  String _classification = 'internal';
  bool _running = false;

  @override
  void initState() {
    super.initState();
    Future.wait([ref.read(foldersApiProvider).list(), ref.read(documentTypesApiProvider).list()]).then((r) {
      if (mounted) {
        setState(() {
          _folders = (r[0] as List<FolderRow>)..sort((a, b) => a.path.compareTo(b.path));
          _types = r[1] as List<DocumentTypeRow>;
        });
      }
    });
  }

  Future<void> _run() async {
    setState(() => _running = true);
    try {
      final result = await ref
          .read(integrationsApiProvider)
          .registerFolder(
            widget.integrationId,
            prefix: widget.prefix,
            parentFolderId: _parentId,
            recursive: _recursive,
            documentTypeId: _typeId,
            classification: _classification,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      final skipped = result.skipped.isEmpty ? '' : '\n\nSkipped ${result.skipped.length}:\n${result.skipped.take(10).join('\n')}';
      await ResultDialog.showSuccess(context, 'Registered ${result.folders} folder(s) and ${result.imported} file(s).$skipped');
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _running = false);
        await ResultDialog.showError(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final name = widget.prefix.split('/').last;
    return AlertDialog(
      title: Text('Register "$name" in the Repository'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creates a Repository folder linked to this storage folder and registers the files already in it — '
              'nothing is copied or moved. Files already in the Repository are skipped.',
              style: TextStyle(fontSize: 12, color: tokens.ink2),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int?>(
              initialValue: _parentId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Place under'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('File Plan root')),
                for (final f in _folders)
                  DropdownMenuItem<int?>(
                    value: f.id,
                    child: Text(f.path, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _parentId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _typeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Document type'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Detect automatically for each file')),
                for (final t in _types) DropdownMenuItem<int?>(value: t.id, child: Text(t.name)),
              ],
              onChanged: (v) => setState(() => _typeId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _classification,
              decoration: const InputDecoration(labelText: 'Classification'),
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Public')),
                DropdownMenuItem(value: 'internal', child: Text('Internal')),
                DropdownMenuItem(value: 'restricted', child: Text('Restricted')),
                DropdownMenuItem(value: 'confidential', child: Text('Confidential')),
              ],
              onChanged: (v) => setState(() => _classification = v ?? 'internal'),
            ),
            CheckboxListTile(
              value: _recursive,
              onChanged: (v) => setState(() => _recursive = v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Include subfolders'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _running ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _running ? null : _run,
          child: _running ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Register'),
        ),
      ],
    );
  }
}
