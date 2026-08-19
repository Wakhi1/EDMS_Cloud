import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/document_record.dart';
import '../../../core/models/workflow_row.dart';
import '../../../core/theme/pspf_tokens.dart';

/// Search-and-pick a document to start [workflow] on. Returns the chosen
/// document's id, or null if cancelled. Mirrors RouteForApprovalDialog's
/// role (a pure picker — the caller makes the actual startInstance call)
/// but searches for a document instead of a workflow, since this dialog is
/// reached from the Workflow Designer with the workflow already fixed.
class StartWorkflowDialog extends ConsumerStatefulWidget {
  const StartWorkflowDialog({super.key, required this.workflow});

  final WorkflowRow workflow;

  @override
  ConsumerState<StartWorkflowDialog> createState() => _StartWorkflowDialogState();
}

class _StartWorkflowDialogState extends ConsumerState<StartWorkflowDialog> {
  final _queryController = TextEditingController();
  List<DocumentRecord>? _results;
  bool _searching = false;
  String? _error;
  DocumentRecord? _selected;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _queryController.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await ref.read(documentsApiProvider).search(q: q);
      if (mounted) setState(() => _results = results);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AlertDialog(
      title: Text('Start "${widget.workflow.name}"'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Search records by title, record no, or member', isDense: true),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _searching ? null : _search, child: const Text('Search')),
              ],
            ),
            const SizedBox(height: 10),
            if (_searching) const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
            if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: TextStyle(color: tokens.bad))),
            if (_results != null)
              Expanded(
                child: _results!.isEmpty
                    ? Center(child: Text('No matching records.', style: TextStyle(color: tokens.ink2)))
                    : ListView(
                        children: [
                          for (final doc in _results!)
                            RadioListTile<int>(
                              value: doc.id,
                              groupValue: _selected?.id,
                              dense: true,
                              title: Text(doc.title, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${doc.recordNo} · ${doc.status}', style: const TextStyle(fontSize: 11.5)),
                              onChanged: (_) => setState(() => _selected = doc),
                            ),
                        ],
                      ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _selected == null ? null : () => Navigator.of(context).pop(_selected!.id),
          child: const Text('Start'),
        ),
      ],
    );
  }
}
