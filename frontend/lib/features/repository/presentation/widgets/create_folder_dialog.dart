import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/folder_row.dart';
import '../../../../core/theme/pspf_tokens.dart';
import '../../../integrations/presentation/storage_browser_dialog.dart';
import '../../../integrations/providers/integrations_providers.dart';

/// Name, parent folder, and (optionally) a default storage location for a
/// new repository folder (`POST /api/folders`) — the sole place folder
/// creation happens in the app; Smart Upload no longer creates folders
/// inline, to avoid two divergent creation UIs for the same underlying
/// resource. Returns null on cancel.
class CreateFolderDialog extends ConsumerStatefulWidget {
  const CreateFolderDialog({super.key, required this.folders, this.initialParentId});

  final List<FolderRow> folders;
  final int? initialParentId;

  static Future<({String name, int? parentId, String? storageProviderId, String? storagePrefix})?> show(
    BuildContext context, {
    required List<FolderRow> folders,
    int? initialParentId,
  }) {
    return showDialog(
      context: context,
      builder: (_) => CreateFolderDialog(folders: folders, initialParentId: initialParentId),
    );
  }

  @override
  ConsumerState<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends ConsumerState<CreateFolderDialog> {
  final _nameController = TextEditingController();
  late int? _parentId = widget.initialParentId;
  String? _storageProviderId;
  String? _storagePrefix;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _browsePrefix(List<({String id, String name})> options) async {
    final integration = options.firstWhere((i) => i.id == _storageProviderId);
    final chosen = await showDialog<String>(
      context: context,
      builder: (_) => StorageBrowserDialog(
        integrationId: integration.id,
        integrationName: integration.name,
        selectMode: true,
        initialPrefix: _storagePrefix ?? '',
      ),
    );
    if (chosen != null) setState(() => _storagePrefix = chosen);
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name: name, parentId: _parentId, storageProviderId: _storageProviderId, storagePrefix: _storagePrefix));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final storageOptions = ref.watch(storageOptionsProvider).valueOrNull ?? const <({String id, String name})>[];

    return AlertDialog(
      title: const Text('New folder'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Folder name', isDense: true),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int?>(
                initialValue: _parentId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Parent folder (optional)', isDense: true),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None — top level')),
                  for (final f in widget.folders) DropdownMenuItem(value: f.id, child: Text(f.path, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _parentId = v),
              ),
              const SizedBox(height: 14),
              Text('DEFAULT STORAGE LOCATION (OPTIONAL)', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(
                'Where documents filed into this folder are stored, unless overridden per upload. Leave unset to use whatever\'s globally active.',
                style: TextStyle(fontSize: 11.5, color: tokens.ink2),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _storageProviderId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Provider', isDense: true),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Automatic (no folder-level default)')),
                  for (final o in storageOptions) DropdownMenuItem(value: o.id, child: Text(o.name)),
                ],
                onChanged: (v) => setState(() {
                  _storageProviderId = v;
                  _storagePrefix = null;
                }),
              ),
              if (_storageProviderId != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _storagePrefix == null || _storagePrefix!.isEmpty
                            ? 'Folder within provider: root'
                            : 'Folder within provider: $_storagePrefix',
                        style: TextStyle(fontSize: 12, color: tokens.ink2),
                      ),
                    ),
                    TextButton(onPressed: () => _browsePrefix(storageOptions), child: const Text('Browse / New folder')),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}
