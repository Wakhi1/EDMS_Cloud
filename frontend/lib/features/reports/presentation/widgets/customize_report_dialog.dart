import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_providers.dart';
import '../../../../core/models/report_template_row.dart';
import '../../providers/reports_providers.dart';

/// Lets the user pick which KPI/graph sections show on screen (and, via the
/// same selection, get included in an export), and save/load that
/// selection as a personal named view. Tapping a saved view applies it and
/// closes immediately — the checkbox list below is for ad-hoc tweaks and
/// saving a new view, not a two-step "load then confirm" flow.
class CustomizeReportDialog extends ConsumerStatefulWidget {
  const CustomizeReportDialog({super.key});

  @override
  ConsumerState<CustomizeReportDialog> createState() => _CustomizeReportDialogState();
}

class _CustomizeReportDialogState extends ConsumerState<CustomizeReportDialog> {
  late Set<String> _checked;
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _checked = Set.of(ref.read(selectedReportSectionsProvider));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _applyTemplate(ReportTemplateRow t) {
    ref.read(selectedReportSectionsProvider.notifier).state = t.sections.toSet();
    Navigator.of(context).pop();
  }

  Future<void> _deleteTemplate(ReportTemplateRow t) async {
    try {
      await ref.read(reportTemplatesApiProvider).delete(t.id);
      ref.invalidate(reportTemplateListProvider);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _saveAsNew() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _checked.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(reportTemplatesApiProvider).create(name: name, sections: _checked.toList());
      ref.invalidate(reportTemplateListProvider);
      _nameController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved "$name".')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _apply() {
    ref.read(selectedReportSectionsProvider.notifier).state = _checked;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(reportTemplateListProvider);

    return AlertDialog(
      title: const Text('Customize report'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saved views', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              templatesAsync.when(
                loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),
                error: (_, _) => const SizedBox.shrink(),
                data: (templates) {
                  if (templates.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('None saved yet.', style: TextStyle(color: Theme.of(context).hintColor)),
                    );
                  }
                  return Column(
                    children: [
                      for (final t in templates)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(t.name),
                          subtitle: Text('${t.sections.length} section${t.sections.length == 1 ? '' : 's'}'),
                          onTap: () => _applyTemplate(t),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            tooltip: 'Delete this view',
                            onPressed: () => _deleteTemplate(t),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const Divider(height: 24),
              Text('Sections to show', style: Theme.of(context).textTheme.labelLarge),
              for (final def in kReportSectionDefs)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _checked.contains(def.$1),
                  title: Text(def.$2),
                  onChanged: (v) => setState(() => v == true ? _checked.add(def.$1) : _checked.remove(def.$1)),
                ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Save current selection as...', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _saving ? null : _saveAsNew, child: const Text('Save')),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _checked.isEmpty ? null : _apply, child: const Text('Apply')),
      ],
    );
  }
}
