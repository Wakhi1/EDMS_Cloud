// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuditLogRow _$AuditLogRowFromJson(Map<String, dynamic> json) => _AuditLogRow(
  id: (json['id'] as num).toInt(),
  createdAt: json['created_at'] as String,
  userName: json['user_name'] as String?,
  action: json['action'] as String,
  recordType: json['record_type'] as String?,
  recordId: json['record_id'] as String?,
  detail: json['detail'] as String?,
  ipAddress: json['ip_address'] as String?,
);

Map<String, dynamic> _$AuditLogRowToJson(_AuditLogRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt,
      'user_name': instance.userName,
      'action': instance.action,
      'record_type': instance.recordType,
      'record_id': instance.recordId,
      'detail': instance.detail,
      'ip_address': instance.ipAddress,
    };
