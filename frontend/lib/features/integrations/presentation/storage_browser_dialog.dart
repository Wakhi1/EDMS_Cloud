import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/pspf_tokens.dart';

/// Browses and creates "folders" (prefixes/directories) inside a
/// storage-type integration's real backend — a plain object/prefix browser
/// against the provider's own SDK, unrelated to the app's logical MySQL
/// file-plan `folders` table used by the Repository screen.
class StorageBrowserDialog extends ConsumerStatefulWidget {
  const StorageBrowserDialog({
    super.key,
    required this.integrationId,
    required this.integrationName,
    this.selectMode = false,
    this.initialPrefix = '',
  });

  final String integrationId;
  final String integrationName;

  /// When true, shows a "Select this folder" action that pops the dialog
  /// with the current prefix (`Navigator.pop<String>`) — used by Smart
  /// Upload to pick/create a storage folder rather than just browse it.
  final bool selectMode;

  /// Starting prefix to browse from (e.g. a folder path already derived
  /// from the chosen repository folder).
  final String initialPrefix;

  @override
  ConsumerState<StorageBrowserDialog> createState() => _StorageBrowserDialogState();
}

class _StorageBrowserDialogState extends ConsumerState<StorageBrowserDialog> {
  late String _prefix = widget.initialPrefix;
  bool _loading = true;
  String? _error;
  List<String> _folders = [];
  List<String> _files = [];
  final _newFolderController = TextEditingController();
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newFolderController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(integrationsApiProvider).browse(widget.integrationId, prefix: _prefix);
      setState(() {
        _folders = result.folders;
        _files = result.files;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _descend(String folder) {
    setState(() => _prefix = _prefix.isEmpty ? folder : '$_prefix/$folder');
    _load();
  }

  void _jumpTo(int breadcrumbIndex) {
    final segments = _prefix.split('/').where((s) => s.isNotEmpty).toList();
    setState(() => _prefix = segments.take(breadcrumbIndex).join('/'));
    _load();
  }

  Future<void> _createFolder() async {
    final name = _newFolderController.text.trim();
    if (name.isEmpty) return;
    setState(() => _creating = true);
    try {
      final newPrefix = await ref.read(integrationsApiProvider).createFolder(widget.integrationId, prefix: _prefix, name: name);
      _newFolderController.clear();
      setState(() => _prefix = newPrefix);
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final segments = _prefix.split('/').where((s) => s.isNotEmpty).toList();

    return AlertDialog(
      title: Text(widget.selectMode ? 'Choose a folder — ${widget.integrationName}' : 'Browse — ${widget.integrationName}'),
      content: SizedBox(
        width: 440,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InkWell(onTap: () => _jumpTo(0), child: const Padding(padding: EdgeInsets.all(4), child: Text('root'))),
                for (var i = 0; i < segments.length; i++) ...[
                  Text(' / ', style: TextStyle(color: tokens.ink3)),
                  InkWell(
                    onTap: () => _jumpTo(i + 1),
                    child: Padding(padding: const EdgeInsets.all(4), child: Text(segments[i])),
                  ),
                ],
              ],
            ),
            const Divider(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: TextStyle(color: tokens.bad)))
                      : (_folders.isEmpty && _files.isEmpty)
                          ? Center(child: Text('Empty.', style: TextStyle(color: tokens.ink2)))
                          : ListView(
                              children: [
                                for (final folder in _folders)
                                  ListTile(
                                    dense: true,
                                    leading: Icon(PhosphorIconsDuotone.folder, color: tokens.accD),
                                    title: Text(folder),
                                    onTap: () => _descend(folder),
                                  ),
                                for (final file in _files)
                                  ListTile(
                                    dense: true,
                                    leading: Icon(PhosphorIconsDuotone.file, color: tokens.ink3),
                                    title: Text(file, style: TextStyle(color: tokens.ink2)),
                                  ),
                              ],
                            ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newFolderController,
                    decoration: const InputDecoration(isDense: true, hintText: 'New folder name'),
                    onSubmitted: (_) => _createFolder(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _creating ? null : _createFolder,
                  child: _creating
                      ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.selectMode ? 'Cancel' : 'Close'),
        ),
        if (widget.selectMode)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_prefix),
            child: Text(_prefix.isEmpty ? 'Select root' : 'Select "$_prefix"'),
          ),
      ],
    );
  }
}
