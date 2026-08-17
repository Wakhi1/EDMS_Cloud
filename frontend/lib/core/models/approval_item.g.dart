// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApprovalItem _$ApprovalItemFromJson(Map<String, dynamic> json) =>
    _ApprovalItem(
      approvalId: (json['approval_id'] as num).toInt(),
      instanceId: (json['instance_id'] as num).toInt(),
      stepId: (json['step_id'] as num).toInt(),
      documentId: (json['document_id'] as num).toInt(),
      recordNo: json['record_no'] as String,
      title: json['title'] as String,
      stepName: json['step_name'] as String,
      slaDays: (json['sla_days'] as num?)?.toInt(),
      startedAt: json['started_at'] as String?,
      escalatedAt: json['escalated_at'] as String?,
    );

Map<String, dynamic> _$ApprovalItemToJson(_ApprovalItem instance) =>
    <String, dynamic>{
      'approval_id': instance.approvalId,
      'instance_id': instance.instanceId,
      'step_id': instance.stepId,
      'document_id': instance.documentId,
      'record_no': instance.recordNo,
      'title': instance.title,
      'step_name': instance.stepName,
      'sla_days': instance.slaDays,
      'started_at': instance.startedAt,
      'escalated_at': instance.escalatedAt,
    };
