// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retention_class_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RetentionClassRow _$RetentionClassRowFromJson(Map<String, dynamic> json) =>
    _RetentionClassRow(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      name: json['name'] as String,
      retentionYears: (json['retention_years'] as num).toInt(),
      triggerEvent: json['trigger_event'] as String?,
      disposalAction: json['disposal_action'] as String,
      requiresRecordsManagerApproval: _boolFromInt(
        json['requires_records_manager_approval'],
      ),
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$RetentionClassRowToJson(
  _RetentionClassRow instance,
) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'retention_years': instance.retentionYears,
  'trigger_event': instance.triggerEvent,
  'disposal_action': instance.disposalAction,
  'requires_records_manager_approval': instance.requiresRecordsManagerApproval,
  'created_at': instance.createdAt,
};
