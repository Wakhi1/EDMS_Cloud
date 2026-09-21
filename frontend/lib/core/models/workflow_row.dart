// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workflow_row.freezed.dart';
part 'workflow_row.g.dart';

/// A step within a workflow, as nested under GET /api/workflow.
@freezed
abstract class WorkflowStepRow with _$WorkflowStepRow {
  const factory WorkflowStepRow({
    required int id,
    @JsonKey(name: 'workflow_id') required int workflowId,
    @JsonKey(name: 'step_order') required int stepOrder,
    @JsonKey(name: 'step_name') required String stepName,
    @JsonKey(name: 'role_id') required int roleId,
    @JsonKey(name: 'role_name') String? roleName,
    @JsonKey(name: 'assignee_user_id') int? assigneeUserId,
    @JsonKey(name: 'assignee_name') String? assigneeName,
    @JsonKey(name: 'sla_days') int? slaDays,
    @JsonKey(name: 'escalation_role_id') int? escalationRoleId,
    @JsonKey(name: 'escalation_role_name') String? escalationRoleName,
    @JsonKey(name: 'sub_workflow_id') int? subWorkflowId,
    @JsonKey(name: 'sub_workflow_name') String? subWorkflowName,
    @JsonKey(name: 'requires_signature', fromJson: _boolFromInt) @Default(false) bool requiresSignature,
  }) = _WorkflowStepRow;

  factory WorkflowStepRow.fromJson(Map<String, dynamic> json) => _$WorkflowStepRowFromJson(json);
}

/// A workflow with its ordered steps, from GET /api/workflow.
@freezed
abstract class WorkflowRow with _$WorkflowRow {
  const factory WorkflowRow({
    required int id,
    required String name,
    @JsonKey(name: 'trigger_doc_type_id') int? triggerDocTypeId,
    @JsonKey(name: 'trigger_folder_id') int? triggerFolderId,
    @JsonKey(name: 'is_active', fromJson: _boolFromInt) @Default(true) bool isActive,
    @JsonKey(name: 'schedule_enabled', fromJson: _boolFromInt) @Default(false) bool scheduleEnabled,
    @JsonKey(name: 'schedule_target_document_id') int? scheduleTargetDocumentId,
    @JsonKey(name: 'schedule_target_document_record_no') String? scheduleTargetDocumentRecordNo,
    @JsonKey(name: 'schedule_target_document_title') String? scheduleTargetDocumentTitle,
    @JsonKey(name: 'schedule_start_at') String? scheduleStartAt,
    @JsonKey(name: 'schedule_recurrence') String? scheduleRecurrence,
    @JsonKey(name: 'schedule_end_at') String? scheduleEndAt,
    @JsonKey(name: 'schedule_next_run_at') String? scheduleNextRunAt,
    @Default(<WorkflowStepRow>[]) List<WorkflowStepRow> steps,
  }) = _WorkflowRow;

  factory WorkflowRow.fromJson(Map<String, dynamic> json) => _$WorkflowRowFromJson(json);
}

bool _boolFromInt(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return true;
}
