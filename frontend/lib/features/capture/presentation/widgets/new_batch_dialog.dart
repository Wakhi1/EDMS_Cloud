import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/folder_row.dart';
import '../../../../core/theme/pspf_tokens.dart';
import '../../../../core/utils/mime_type.dart';

/// Picks multiple files for a bulk "batching of documents" upload — no
/// per-file review table like Smart Upload (that's for a single deliberate
/// session); this is a dump-and-go batch, matching a real scan-station
/// workflow. The 'device' source option covers "device upload": on a
/// mobile browser, the same file picker already opens the camera/gallery
/// natively, so no separate device-capture API is needed.
class NewBatchDialog extends StatefulWidget {
  const NewBatchDialog({super.key, required this.folders});

  final List<FolderRow> folders;

  static Future<({List<({List<int> bytes, String fileName, String mimeType})> files, String source, int folderId})?> show(
    BuildContext context, {
    required List<FolderRow> folders,
  }) {
    return showDialog(context: context, builder: (_) => NewBatchDialog(folders: folders));
  }

  @override
  State<NewBatchDialog> createState() => _NewBatchDialogState();
}

class _NewBatchDialogState extends State<NewBatchDialog> {
  List<PlatformFile> _picked = [];
  String _source = 'manual_upload';
  int? _folderId;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    if (widget.folders.isNotEmpty) _folderId = widget.folders.first.id;
  }

  Future<void> _pickFiles() async {
    setState(() => _picking = true);
    try {
      final picked = await FilePicker.pickFiles(); // multi-select by default
      setState(() => _picked = picked);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit() async {
    if (_picked.isEmpty || _folderId == null) return;
    final files = [
      for (final f in _picked)
        (bytes: await f.readAsBytes(), fileName: f.name, mimeType: mimeTypeForExtension(extensionOf(f.name))),
    ];
    if (mounted) Navigator.of(context).pop((files: files, source: _source, folderId: _folderId!));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AlertDialog(
      title: const Text('New batch'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: _picking ? null : _pickFiles,
              icon: const Icon(Icons.add, size: 16),
              label: Text(_picked.isEmpty ? 'Choose files' : '${_picked.length} file(s) selected'),
            ),
            if (_picked.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView(
                  children: [for (final f in _picked) Text(f.name, style: TextStyle(fontSize: 12, color: tokens.ink2))],
                ),
              ),
            ],
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _source,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Source', isDense: true),
              items: const [
                DropdownMenuItem(value: 'manual_upload', child: Text('Manual upload')),
                DropdownMenuItem(value: 'device_upload', child: Text('Device upload (camera/gallery)')),
              ],
              onChanged: (v) => setState(() => _source = v ?? _source),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _folderId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Destination folder', isDense: true),
              items: [for (final f in widget.folders) DropdownMenuItem(value: f.id, child: Text(f.path, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _folderId = v),
            ),
            const SizedBox(height: 8),
            Text(
              'Each file is auto-classified and registered immediately — encrypted, OCR\'d, and indexed the same as any other document.',
              style: TextStyle(fontSize: 11.5, color: tokens.ink2),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: (_picked.isEmpty || _folderId == null) ? null : _submit,
          child: const Text('Upload batch'),
        ),
      ],
    );
  }
}
