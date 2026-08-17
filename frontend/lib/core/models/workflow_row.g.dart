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
      slaDays: (json['sla_days'] as num?)?.toInt(),
      escalationRoleId: (json['escalation_role_id'] as num?)?.toInt(),
      escalationRoleName: json['escalation_role_name'] as String?,
      subWorkflowId: (json['sub_workflow_id'] as num?)?.toInt(),
      subWorkflowName: json['sub_workflow_name'] as String?,
    );

Map<String, dynamic> _$WorkflowStepRowToJson(_WorkflowStepRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workflow_id': instance.workflowId,
      'step_order': instance.stepOrder,
      'step_name': instance.stepName,
      'role_id': instance.roleId,
      'role_name': instance.roleName,
      'sla_days': instance.slaDays,
      'escalation_role_id': instance.escalationRoleId,
      'escalation_role_name': instance.escalationRoleName,
      'sub_workflow_id': instance.subWorkflowId,
      'sub_workflow_name': instance.subWorkflowName,
    };

_WorkflowRow _$WorkflowRowFromJson(Map<String, dynamic> json) => _WorkflowRow(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  triggerDocTypeId: (json['trigger_doc_type_id'] as num?)?.toInt(),
  triggerFolderId: (json['trigger_folder_id'] as num?)?.toInt(),
  isActive: json['is_active'] == null ? true : _boolFromInt(json['is_active']),
  steps:
      (json['steps'] as List<dynamic>?)
          ?.map((e) => WorkflowStepRow.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <WorkflowStepRow>[],
);

Map<String, dynamic> _$WorkflowRowToJson(_WorkflowRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'trigger_doc_type_id': instance.triggerDocTypeId,
      'trigger_folder_id': instance.triggerFolderId,
      'is_active': instance.isActive,
      'steps': instance.steps,
    };
