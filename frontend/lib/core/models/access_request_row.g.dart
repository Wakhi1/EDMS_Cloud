// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_request_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccessRequestRow _$AccessRequestRowFromJson(Map<String, dynamic> json) =>
    _AccessRequestRow(
      id: (json['id'] as num).toInt(),
      targetType: json['target_type'] as String,
      targetId: (json['target_id'] as num).toInt(),
      requestedLevel: json['requested_level'] as String,
      reason: json['reason'] as String?,
      requesterId: (json['requester_id'] as num).toInt(),
      requesterName: json['requester_name'] as String?,
      status: json['status'] as String,
      decidedBy: (json['decided_by'] as num?)?.toInt(),
      decidedByName: json['decided_by_name'] as String?,
      decidedAt: json['decided_at'] as String?,
      decisionNote: json['decision_note'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$AccessRequestRowToJson(_AccessRequestRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'target_type': instance.targetType,
      'target_id': instance.targetId,
      'requested_level': instance.requestedLevel,
      'reason': instance.reason,
      'requester_id': instance.requesterId,
      'requester_name': instance.requesterName,
      'status': instance.status,
      'decided_by': instance.decidedBy,
      'decided_by_name': instance.decidedByName,
      'decided_at': instance.decidedAt,
      'decision_note': instance.decisionNote,
      'created_at': instance.createdAt,
    };
