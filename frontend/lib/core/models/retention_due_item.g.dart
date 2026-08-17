// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retention_due_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RetentionDueItem _$RetentionDueItemFromJson(Map<String, dynamic> json) =>
    _RetentionDueItem(
      id: (json['id'] as num).toInt(),
      recordNo: json['record_no'] as String,
      title: json['title'] as String,
      retentionDueAt: json['retention_due_at'] as String,
      disposalAction: json['disposal_action'] as String,
      retentionClassName: json['retention_class_name'] as String?,
    );

Map<String, dynamic> _$RetentionDueItemToJson(_RetentionDueItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'record_no': instance.recordNo,
      'title': instance.title,
      'retention_due_at': instance.retentionDueAt,
      'disposal_action': instance.disposalAction,
      'retention_class_name': instance.retentionClassName,
    };
