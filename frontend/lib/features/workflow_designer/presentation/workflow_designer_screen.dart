import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/auth/known_roles.dart';
import '../../../core/models/workflow_row.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../repository/providers/repository_providers.dart';
import '../providers/workflow_providers.dart';

class WorkflowDesignerScreen extends ConsumerWidget {
  const WorkflowDesignerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1000;

    final list = _ExistingWorkflowsList();
    final form = const _NewWorkflowForm();

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Administration / Workflow Designer', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 340, child: SingleChildScrollView(child: list)),
                      const SizedBox(width: 16),
                      Expanded(child: SingleChildScrollView(child: form)),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(children: [list, const SizedBox(height: 20), form]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExistingWorkflowsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final workflowsAsync = ref.watch(workflowsProvider);

    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text('EXISTING WORKFLOWS', style: textTheme.labelSmall),
          ),
          workflowsAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.bad, fontSize: 12)),
            ),
            data: (workflows) {
              if (workflows.isEmpty) {
                return const Padding(padding: EdgeInsets.all(12), child: EmptyState(message: 'No workflows defined yet.'));
              }
              return Column(
                children: [
                  for (final w in workflows) _WorkflowTile(workflow: w),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WorkflowTile extends StatelessWidget {
  const _WorkflowTile({required this.workflow});

  final WorkflowRow workflow;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(workflow.name, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final s in workflow.steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    color: tokens.acc,
                    child: Text('${s.stepOrder}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${s.stepName} · ${s.roleName ?? 'role #${s.roleId}'} · SLA ${s.slaDays ?? '—'}d'
                      '${s.subWorkflowId != null ? ' · sub-workflow: ${s.subWorkflowName ?? '#${s.subWorkflowId}'}' : ''}'
                      '${s.escalationRoleId != null ? ' · escalates to ${s.escalationRoleName ?? '#${s.escalationRoleId}'}' : ''}',
                      style: TextStyle(fontSize: 12, color: tokens.ink2),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StepDraft {
  String stepName = '';
  int roleId = kDefaultRoleId;
  int slaDays = 2;
  int? escalationRoleId;
  int? subWorkflowId;
}

class _NewWorkflowForm extends ConsumerStatefulWidget {
  const _NewWorkflowForm();

  @override
  ConsumerState<_NewWorkflowForm> createState() => _NewWorkflowFormState();
}

class _NewWorkflowFormState extends ConsumerState<_NewWorkflowForm> {
  final _nameController = TextEditingController();
  int? _triggerDocTypeId;
  int? _triggerFolderId;
  final List<_StepDraft> _steps = [_StepDraft()];
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Give the workflow a name.')));
      return;
    }
    final steps = _steps.where((s) => s.stepName.trim().isNotEmpty).toList();
    if (steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one named step.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(workflowApiProvider).create(
            name: name,
            triggerDocTypeId: _triggerDocTypeId,
            triggerFolderId: _triggerFolderId,
            steps: [
              for (final s in steps)
                (
                  stepName: s.stepName.trim(),
                  roleId: s.roleId,
                  slaDays: s.slaDays,
                  escalationRoleId: s.escalationRoleId,
                  subWorkflowId: s.subWorkflowId,
                ),
            ],
          );
      ref.invalidate(workflowsProvider);
      if (mounted) {
        setState(() {
          _nameController.clear();
          _triggerDocTypeId = null;
          _triggerFolderId = null;
          _steps
            ..clear()
            ..add(_StepDraft());
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workflow saved.')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final typesAsync = ref.watch(documentTypesProvider);
    final foldersAsync = ref.watch(foldersProvider);
    final availableWorkflows = ref.watch(workflowsProvider).valueOrNull ?? const <WorkflowRow>[];

    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New workflow', style: textTheme.titleSmall),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Workflow name', isDense: true),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _triggerDocTypeId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Trigger document type (optional)', isDense: true),
                  items: [
                    for (final t in typesAsync.valueOrNull ?? const [])
                      DropdownMenuItem(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _triggerDocTypeId = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _triggerFolderId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Trigger folder (optional)', isDense: true),
                  items: [
                    for (final f in foldersAsync.valueOrNull ?? const [])
                      DropdownMenuItem(value: f.id, child: Text(f.path, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _triggerFolderId = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('STEPS', style: textTheme.labelSmall),
          const SizedBox(height: 6),
          for (var i = 0; i < _steps.length; i++) _StepEditor(
                index: i,
                step: _steps[i],
                canMoveUp: i > 0,
                canMoveDown: i < _steps.length - 1,
                canRemove: _steps.length > 1,
                availableWorkflows: availableWorkflows,
                onChanged: () => setState(() {}),
                onMoveUp: () => setState(() {
                  final s = _steps.removeAt(i);
                  _steps.insert(i - 1, s);
                }),
                onMoveDown: () => setState(() {
                  final s = _steps.removeAt(i);
                  _steps.insert(i + 1, s);
                }),
                onRemove: () => setState(() => _steps.removeAt(i)),
              ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () => setState(() => _steps.add(_StepDraft())),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add step'),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save workflow'),
          ),
        ],
      ),
    );
  }
}

class _StepEditor extends StatelessWidget {
  const _StepEditor({
    required this.index,
    required this.step,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.canRemove,
    required this.availableWorkflows,
    required this.onChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final int index;
  final _StepDraft step;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool canRemove;
  final List<WorkflowRow> availableWorkflows;
  final VoidCallback onChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: tokens.line2)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            color: tokens.acc,
            child: Text('${index + 1}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 180,
                  child: TextFormField(
                    initialValue: step.stepName,
                    decoration: const InputDecoration(labelText: 'Step name', isDense: true),
                    onChanged: (v) {
                      step.stepName = v;
                      onChanged();
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<int>(
                    initialValue: step.roleId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Assigned role', isDense: true),
                    items: [
                      for (final r in kKnownRoles) DropdownMenuItem(value: r.id, child: Text(r.name, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) {
                      if (v != null) step.roleId = v;
                      onChanged();
                    },
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    initialValue: '${step.slaDays}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'SLA (days)', isDense: true),
                    onChanged: (v) {
                      step.slaDays = int.tryParse(v) ?? step.slaDays;
                      onChanged();
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<int?>(
                    initialValue: step.escalationRoleId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Escalate to (optional)', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Records Manager (default)')),
                      for (final r in kKnownRoles) DropdownMenuItem(value: r.id, child: Text(r.name, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) {
                      step.escalationRoleId = v;
                      onChanged();
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<int?>(
                    initialValue: step.subWorkflowId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Sub-workflow (optional)', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None — human approval')),
                      for (final w in availableWorkflows) DropdownMenuItem(value: w.id, child: Text(w.name, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) {
                      step.subWorkflowId = v;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(icon: const Icon(Icons.arrow_upward, size: 16), onPressed: canMoveUp ? onMoveUp : null),
              IconButton(icon: const Icon(Icons.arrow_downward, size: 16), onPressed: canMoveDown ? onMoveDown : null),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 16, color: canRemove ? tokens.bad : tokens.ink3),
                onPressed: canRemove ? onRemove : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
