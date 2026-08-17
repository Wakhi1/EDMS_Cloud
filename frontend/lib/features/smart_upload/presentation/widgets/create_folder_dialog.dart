import 'package:flutter/material.dart';

import '../../../../core/models/folder_row.dart';

/// Name + optional parent picker for creating a new repository folder
/// (`POST /api/folders`) inline from Smart Upload, instead of requiring a
/// trip to the Repository screen first. Returns the new folder's id/path on
/// success, or null on cancel — the caller performs the actual API call so
/// it can auto-select the result in the upload queue.
class CreateFolderDialog extends StatefulWidget {
  const CreateFolderDialog({super.key, required this.folders});

  final List<FolderRow> folders;

  static Future<({String name, int? parentId})?> show(BuildContext context, {required List<FolderRow> folders}) {
    return showDialog<({String name, int? parentId})>(
      context: context,
      builder: (_) => CreateFolderDialog(folders: folders),
    );
  }

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final _nameController = TextEditingController();
  int? _parentId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name: name, parentId: _parentId));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New folder'),
      content: SizedBox(
        width: 360,
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
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}
