import 'package:flutter/material.dart';

import '../../../core/models/department_row.dart';
import '../../../core/models/document_record.dart';
import '../../../core/models/document_type_row.dart';
import '../../../core/models/folder_row.dart';

const _kClassifications = <String>['public', 'internal', 'restricted', 'confidential'];

/// Metadata-only editor for an existing document — mirrors what
/// PUT /api/documents/:id actually accepts (title/type/folder/department/
/// member fields/classification). File content and versions aren't
/// editable here; that's Version History's job.
class EditDocumentDialog extends StatefulWidget {
  const EditDocumentDialog({
    super.key,
    required this.doc,
    required this.types,
    required this.folders,
    required this.departments,
  });

  final DocumentRecord doc;
  final List<DocumentTypeRow> types;
  final List<FolderRow> folders;
  final List<DepartmentRow> departments;

  @override
  State<EditDocumentDialog> createState() => _EditDocumentDialogState();
}

class _EditDocumentDialogState extends State<EditDocumentDialog> {
  late final _titleController = TextEditingController(text: widget.doc.title);
  late final _memberNumberController = TextEditingController(text: widget.doc.memberNumber ?? '');
  late final _memberNameController = TextEditingController(text: widget.doc.memberName ?? '');
  late int? _documentTypeId = widget.types.where((t) => t.name == widget.doc.documentType).firstOrNull?.id;
  late int? _folderId = widget.folders.where((f) => f.path == widget.doc.folderPath).firstOrNull?.id;
  late int? _departmentId = widget.departments.where((d) => d.name == widget.doc.department).firstOrNull?.id;
  late String _classification = widget.doc.classification;

  @override
  void dispose() {
    _titleController.dispose();
    _memberNumberController.dispose();
    _memberNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit record'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.doc.recordNo, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 10),
              TextField(controller: _titleController, autofocus: true, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _documentTypeId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Document type'),
                items: [for (final t in widget.types) DropdownMenuItem(value: t.id, child: Text(t.name))],
                onChanged: (v) => setState(() => _documentTypeId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _folderId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Folder'),
                items: [for (final f in widget.folders) DropdownMenuItem(value: f.id, child: Text(f.path, overflow: TextOverflow.ellipsis))],
                onChanged: (v) => setState(() => _folderId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _departmentId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Department (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  for (final d in widget.departments) DropdownMenuItem(value: d.id, child: Text(d.name)),
                ],
                onChanged: (v) => setState(() => _departmentId = v),
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
              TextField(controller: _memberNumberController, decoration: const InputDecoration(labelText: 'Member number (optional)')),
              const SizedBox(height: 12),
              TextField(controller: _memberNameController, decoration: const InputDecoration(labelText: 'Member name (optional)')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty || _documentTypeId == null || _folderId == null) return;
            Navigator.of(context).pop((
              title: _titleController.text.trim(),
              documentTypeId: _documentTypeId!,
              folderId: _folderId!,
              departmentId: _departmentId,
              classification: _classification,
              memberNumber: _memberNumberController.text.trim().isEmpty ? null : _memberNumberController.text.trim(),
              memberName: _memberNameController.text.trim().isEmpty ? null : _memberNameController.text.trim(),
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
