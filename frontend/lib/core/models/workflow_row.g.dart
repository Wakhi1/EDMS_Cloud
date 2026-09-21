// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkflowStepRow _$WorkflowStepRowFromJson(Map<String, dynamic> json) =>
    _WorkflowStepRow(
      id: (json['id'] as num).toInt(),
      workflowId: (json['workflow_id'] as num).toInt(),
      stepOrder: (json['step_order'] as num).toInt(),
      stepName: json['step_name'] as String,
      roleId: (json['role_id'] as num).toInt(),
      roleName: json['role_name'] as String?,
      assigneeUserId: (json['assignee_user_id'] as num?)?.toInt(),
      assigneeName: json['assignee_name'] as String?,
      slaDays: (json['sla_days'] as num?)?.toInt(),
      escalationRoleId: (json['escalation_role_id'] as num?)?.toInt(),
      escalationRoleName: json['escalation_role_name'] as String?,
      subWorkflowId: (json['sub_workflow_id'] as num?)?.toInt(),
      subWorkflowName: json['sub_workflow_name'] as String?,
      requiresSignature: json['requires_signature'] == null
          ? false
          : _boolFromInt(json['requires_signature']),
    );

Map<String, dynamic> _$WorkflowStepRowToJson(_WorkflowStepRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workflow_id': instance.workflowId,
      'step_order': instance.stepOrder,
      'step_name': instance.stepName,
      'role_id': instance.roleId,
      'role_name': instance.roleName,
      'assignee_user_id': instance.assigneeUserId,
      'assignee_name': instance.assigneeName,
      'sla_days': instance.slaDays,
      'escalation_role_id': instance.escalationRoleId,
      'escalation_role_name': instance.escalationRoleName,
      'sub_workflow_id': instance.subWorkflowId,
      'sub_workflow_name': instance.subWorkflowName,
      'requires_signature': instance.requiresSignature,
    };

_WorkflowRow _$WorkflowRowFromJson(Map<String, dynamic> json) => _WorkflowRow(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  triggerDocTypeId: (json['trigger_doc_type_id'] as num?)?.toInt(),
  triggerFolderId: (json['trigger_folder_id'] as num?)?.toInt(),
  isActive: json['is_active'] == null ? true : _boolFromInt(json['is_active']),
  scheduleEnabled: json['schedule_enabled'] == null
      ? false
      : _boolFromInt(json['schedule_enabled']),
  scheduleTargetDocumentId: (json['schedule_target_document_id'] as num?)
      ?.toInt(),
  scheduleTargetDocumentRecordNo:
      json['schedule_target_document_record_no'] as String?,
  scheduleTargetDocumentTitle:
      json['schedule_target_document_title'] as String?,
  scheduleStartAt: json['schedule_start_at'] as String?,
  scheduleRecurrence: json['schedule_recurrence'] as String?,
  scheduleEndAt: json['schedule_end_at'] as String?,
  scheduleNextRunAt: json['schedule_next_run_at'] as String?,
  steps:
      (json['steps'] as List<dynamic>?)
          ?.map((e) => WorkflowStepRow.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <WorkflowStepRow>[],
);

Map<String, dynamic> _$WorkflowRowToJson(
  _WorkflowRow instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'trigger_doc_type_id': instance.triggerDocTypeId,
  'trigger_folder_id': instance.triggerFolderId,
  'is_active': instance.isActive,
  'schedule_enabled': instance.scheduleEnabled,
  'schedule_target_document_id': instance.scheduleTargetDocumentId,
  'schedule_target_document_record_no': instance.scheduleTargetDocumentRecordNo,
  'schedule_target_document_title': instance.scheduleTargetDocumentTitle,
  'schedule_start_at': instance.scheduleStartAt,
  'schedule_recurrence': instance.scheduleRecurrence,
  'schedule_end_at': instance.scheduleEndAt,
  'schedule_next_run_at': instance.scheduleNextRunAt,
  'steps': instance.steps,
};
