import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../permissions/presentation/grant_access_dialog.dart';
import '../../repository/providers/repository_providers.dart';
import '../../retention/providers/retention_providers.dart';
import '../../departments/providers/departments_providers.dart';

const _kClassifications = <String>['public', 'internal', 'restricted', 'confidential'];

/// Configures and runs an import of files already sitting under [prefix] in
/// a storage-type connector (chosen beforehand via StorageBrowserDialog in
/// select mode — this dialog only handles "what happens to them once
/// they're in the Repository", not browsing). System-Administrator-only,
/// matching the backend route's own gate.
class ImportFromStorageDialog extends ConsumerStatefulWidget {
  const ImportFromStorageDialog({super.key, required this.integrationId, required this.integrationName, required this.prefix});

  final String integrationId;
  final String integrationName;
  final String prefix;

  @override
  ConsumerState<ImportFromStorageDialog> createState() => _ImportFromStorageDialogState();
}

class _ImportFromStorageDialogState extends ConsumerState<ImportFromStorageDialog> {
  int? _folderId;
  // Riverpod's AsyncValue.when() defaults to skipLoadingOnRefresh: true —
  // right after ref.invalidate(foldersProvider) below, the very next build
  // still sees the STALE folder list (by design, to avoid a loading
  // flicker), not yet including the folder just created. Selecting it by
  // id immediately would set the dropdown's value to something absent
  // from its own items, which is a real Flutter assertion failure (the
  // "red screen"), not just a race that usually gets lucky. Tracking its
  // path here lets the dropdown always render an item for it until the
  // real list catches up, regardless of exactly when that happens.
  String? _pendingFolderPath;
  int? _documentTypeId;
  String _classification = 'internal';
  int? _departmentId;
  int? _retentionClassId;
  bool _restricted = false;
  final _grants = <({String principalType, int principalId, String permissionLevel})>[];

  final _newFolderController = TextEditingController();
  bool _creatingFolder = false;
  bool _importing = false;

  @override
  void dispose() {
    _newFolderController.dispose();
    super.dispose();
  }

  Future<void> _createFolder() async {
    final name = _newFolderController.text.trim();
    if (name.isEmpty) return;
    setState(() => _creatingFolder = true);
    try {
      final result = await ref.read(foldersApiProvider).create(name: name);
      ref.invalidate(foldersProvider);
      _newFolderController.clear();
      setState(() {
        _folderId = result.id;
        _pendingFolderPath = result.path;
      });
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _creatingFolder = false);
    }
  }

  Future<void> _addGrant() async {
    final result = await showDialog<({String principalType, int principalId, String permissionLevel})>(
      context: context,
      builder: (_) => const GrantAccessDialog(),
    );
    if (result != null) setState(() => _grants.add(result));
  }

  Future<void> _submit() async {
    if (_folderId == null || _documentTypeId == null) return;
    setState(() => _importing = true);
    try {
      final result = await ref.read(integrationsApiProvider).importFromStorage(
            widget.integrationId,
            prefix: widget.prefix,
            folderId: _folderId!,
            documentTypeId: _documentTypeId!,
            classification: _classification,
            departmentId: _departmentId,
            retentionClassId: _retentionClassId,
            grants: _restricted ? _grants : const [],
          );
      if (mounted) Navigator.of(context).pop(result);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(foldersProvider);
    final typesAsync = ref.watch(documentTypesProvider);
    final departmentsAsync = ref.watch(departmentsListProvider);
    final retentionAsync = ref.watch(retentionClassesProvider);

    return AlertDialog(
      title: Text('Import from ${widget.integrationName}'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Source: root/${widget.prefix}', style: Theme.of(context).textTheme.bodySmall),
              Text(
                'Every file directly under this prefix (not subfolders) will be OCR\'d, checksummed, '
                'and registered as a new Repository record. Files matching an existing record\'s content are skipped.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              foldersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (folders) => DropdownButtonFormField<int>(
                  initialValue: _folderId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Destination folder'),
                  items: [
                    for (final f in folders) DropdownMenuItem(value: f.id, child: Text(f.path, overflow: TextOverflow.ellipsis)),
                    // Covers the gap between creating a folder and foldersProvider's
                    // refetch actually resolving — see _pendingFolderPath above.
                    if (_pendingFolderPath != null && _folderId != null && !folders.any((f) => f.id == _folderId))
                      DropdownMenuItem(value: _folderId!, child: Text(_pendingFolderPath!, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() {
                    _folderId = v;
                    _pendingFolderPath = null;
                  }),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newFolderController,
                      decoration: const InputDecoration(isDense: true, hintText: 'Or create a new folder'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _creatingFolder ? null : _createFolder,
                    child: _creatingFolder
                        ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Create'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              typesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (types) => DropdownButtonFormField<int>(
                  initialValue: _documentTypeId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Document type'),
                  items: [for (final t in types) DropdownMenuItem(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis))],
                  onChanged: (v) => setState(() => _documentTypeId = v),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _classification,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Classification'),
                items: [for (final c in _kClassifications) DropdownMenuItem(value: c, child: Text(c))],
                onChanged: (v) => setState(() => _classification = v ?? _classification),
              ),
              const SizedBox(height: 12),
              departmentsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (depts) => DropdownButtonFormField<int?>(
                  initialValue: _departmentId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Department (optional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    for (final d in depts) DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _departmentId = v),
                ),
              ),
              const SizedBox(height: 12),
              retentionAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (classes) => DropdownButtonFormField<int?>(
                  initialValue: _retentionClassId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Retention class (optional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    for (final c in classes) DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _retentionClassId = v),
                ),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Restrict access'),
                subtitle: Text(
                  _restricted
                      ? 'Only the grants below (plus System Administrator) can see this folder.'
                      : 'Visible to anyone whose role already has Repository access — same default as any other folder.',
                  style: const TextStyle(fontSize: 11.5),
                ),
                value: _restricted,
                onChanged: (v) => setState(() => _restricted = v),
              ),
              if (_restricted) ...[
                for (final g in _grants)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${g.principalType} #${g.principalId}', style: const TextStyle(fontSize: 12.5)),
                    subtitle: Text(g.permissionLevel, style: const TextStyle(fontSize: 11)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _grants.remove(g)),
                    ),
                  ),
                OutlinedButton.icon(onPressed: _addGrant, icon: const Icon(Icons.add, size: 14), label: const Text('Add grant')),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: (_folderId == null || _documentTypeId == null || _importing) ? null : _submit,
          child: _importing
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Import'),
        ),
      ],
    );
  }
}
