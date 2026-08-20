import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/role_row.dart';
import '../../../core/models/workflow_row.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/result_dialog.dart';
import '../../../core/widgets/status_chip.dart';
import '../../repository/providers/repository_providers.dart';
import '../../users/providers/users_providers.dart';
import '../providers/workflow_providers.dart';
import 'start_workflow_dialog.dart';

class WorkflowDesignerScreen extends ConsumerWidget {
  const WorkflowDesignerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1000;

    final editingId = ref.watch(editingWorkflowIdProvider);
    final workflows = ref.watch(workflowsProvider).valueOrNull ?? const <WorkflowRow>[];
    final editingWorkflow = editingId == null ? null : workflows.where((w) => w.id == editingId).firstOrNull;

    final list = _ExistingWorkflowsList();
    // Keyed on the workflow being edited (or 'new') so switching targets
    // fully remounts the form's state instead of trying to sync controllers
    // and the step list mid-flight.
    final form = _WorkflowForm(key: ValueKey(editingWorkflow?.id ?? 'new'), editing: editingWorkflow);

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

class _WorkflowTile extends ConsumerStatefulWidget {
  const _WorkflowTile({required this.workflow});

  final WorkflowRow workflow;

  @override
  ConsumerState<_WorkflowTile> createState() => _WorkflowTileState();
}

class _WorkflowTileState extends ConsumerState<_WorkflowTile> {
  bool _busy = false;

  Future<void> _start(BuildContext context) async {
    final documentId = await showDialog<int>(context: context, builder: (_) => StartWorkflowDialog(workflow: widget.workflow));
    if (documentId == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(workflowApiProvider).startInstance(workflowId: widget.workflow.id, documentId: documentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Started "${widget.workflow.name}" on the selected record.')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleActive(BuildContext context) async {
    setState(() => _busy = true);
    try {
      await ref.read(workflowApiProvider).update(widget.workflow.id, isActive: !widget.workflow.isActive);
      ref.invalidate(workflowsProvider);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete "${widget.workflow.name}"?',
      body: 'Refused if any instance of this workflow is still in progress.',
      okLabel: 'Delete',
      danger: true,
    );
    if (confirmed == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(workflowApiProvider).delete(widget.workflow.id);
      if (ref.read(editingWorkflowIdProvider) == widget.workflow.id) {
        ref.read(editingWorkflowIdProvider.notifier).state = null;
      }
      ref.invalidate(workflowsProvider);
      if (mounted) await ResultDialog.showSuccess(context, 'Workflow deleted.');
    } on ApiException catch (e) {
      if (mounted) await ResultDialog.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final workflow = widget.workflow;
    final isEditing = ref.watch(editingWorkflowIdProvider) == workflow.id;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.line)),
        color: isEditing ? tokens.surf2 : null,
      ),
      child: Opacity(
        opacity: _busy ? 0.6 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(workflow.name, style: Theme.of(context).textTheme.titleSmall)),
                StatusChip(workflow.isActive ? 'Active' : 'Inactive', tone: workflow.isActive ? StatusTone.ok : StatusTone.plain),
              ],
            ),
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                OutlinedButton(
                  onPressed: _busy || workflow.steps.isEmpty || !workflow.isActive ? null : () => _start(context),
                  child: const Text('Start'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : () => ref.read(editingWorkflowIdProvider.notifier).state = isEditing ? null : workflow.id,
                  child: Text(isEditing ? 'Cancel edit' : 'Edit'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : () => _toggleActive(context),
                  child: Text(workflow.isActive ? 'Deactivate' : 'Activate'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : () => _delete(context),
                  style: OutlinedButton.styleFrom(foregroundColor: tokens.bad, side: BorderSide(color: tokens.bad)),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDraft {
  String stepName = '';
  // No hardcoded default: role ids are per-company now (multi-tenant —
  // "Records Officer" is id 1 only for whichever company was created
  // first), so a fixed id can silently point at nothing, or at a
  // different company's role, for anyone else. Left unset until the user
  // actually picks one; validated in _WorkflowFormState._submit().
  int? roleId;
  int slaDays = 2;
  int? escalationRoleId;
  int? subWorkflowId;
}

class _WorkflowForm extends ConsumerStatefulWidget {
  const _WorkflowForm({super.key, this.editing});

  /// The workflow being edited, or null for "new workflow" mode. The widget
  /// is keyed on this in the parent so switching targets remounts fresh
  /// state rather than trying to sync controllers mid-flight.
  final WorkflowRow? editing;

  @override
  ConsumerState<_WorkflowForm> createState() => _WorkflowFormState();
}

class _WorkflowFormState extends ConsumerState<_WorkflowForm> {
  late final _nameController = TextEditingController(text: widget.editing?.name ?? '');
  late int? _triggerDocTypeId = widget.editing?.triggerDocTypeId;
  late int? _triggerFolderId = widget.editing?.triggerFolderId;
  late final List<_StepDraft> _steps = widget.editing == null || widget.editing!.steps.isEmpty
      ? [_StepDraft()]
      : [
          for (final s in widget.editing!.steps)
            _StepDraft()
              ..stepName = s.stepName
              ..roleId = s.roleId
              ..slaDays = s.slaDays ?? 2
              ..escalationRoleId = s.escalationRoleId
              ..subWorkflowId = s.subWorkflowId,
        ];
  bool _submitting = false;

  bool get _isEditing => widget.editing != null;

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
    if (steps.any((s) => s.roleId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick an assigned role for every step.')));
      return;
    }
    final stepTuples = [
      for (final s in steps)
        (
          stepName: s.stepName.trim(),
          roleId: s.roleId!,
          slaDays: s.slaDays,
          escalationRoleId: s.escalationRoleId,
          subWorkflowId: s.subWorkflowId,
        ),
    ];

    setState(() => _submitting = true);
    try {
      if (_isEditing) {
        await ref.read(workflowApiProvider).update(widget.editing!.id, name: name, steps: stepTuples);
        ref.read(editingWorkflowIdProvider.notifier).state = null;
      } else {
        await ref.read(workflowApiProvider).create(
              name: name,
              triggerDocTypeId: _triggerDocTypeId,
              triggerFolderId: _triggerFolderId,
              steps: stepTuples,
            );
      }
      ref.invalidate(workflowsProvider);
      if (mounted) {
        if (!_isEditing) {
          setState(() {
            _nameController.clear();
            _triggerDocTypeId = null;
            _triggerFolderId = null;
            _steps
              ..clear()
              ..add(_StepDraft());
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? 'Workflow updated.' : 'Workflow saved.')));
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
    final roles = ref.watch(rolesProvider).valueOrNull ?? const <RoleRow>[];

    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_isEditing ? 'Edit workflow' : 'New workflow', style: textTheme.titleSmall),
              if (_isEditing) ...[
                const Spacer(),
                TextButton(
                  onPressed: () => ref.read(editingWorkflowIdProvider.notifier).state = null,
                  child: const Text('Cancel edit'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Workflow name', isDense: true),
          ),
          const SizedBox(height: 10),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Trigger document type/folder are fixed at creation and can\'t be changed here.',
                style: TextStyle(fontSize: 11.5, color: tokens.ink2),
              ),
            )
          else
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
                roles: roles,
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
                : Text(_isEditing ? 'Save changes' : 'Save workflow'),
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
    required this.roles,
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
  final List<RoleRow> roles;
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
                  child: DropdownButtonFormField<int?>(
                    initialValue: step.roleId,
                    isExpanded: true,
                    hint: const Text('Select a role', overflow: TextOverflow.ellipsis),
                    decoration: const InputDecoration(labelText: 'Assigned role', isDense: true),
                    items: [
                      for (final r in roles) DropdownMenuItem(value: r.id, child: Text(r.name, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) {
                      step.roleId = v;
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
                      for (final r in roles) DropdownMenuItem(value: r.id, child: Text(r.name, overflow: TextOverflow.ellipsis)),
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
