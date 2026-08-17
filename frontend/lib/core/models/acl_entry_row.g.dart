// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'acl_entry_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AclEntryRow _$AclEntryRowFromJson(Map<String, dynamic> json) => _AclEntryRow(
  id: (json['id'] as num).toInt(),
  targetType: json['target_type'] as String,
  targetId: (json['target_id'] as num).toInt(),
  principalType: json['principal_type'] as String,
  principalId: (json['principal_id'] as num).toInt(),
  principalName: json['principal_name'] as String?,
  permissionLevel: json['permission_level'] as String,
  grantedBy: (json['granted_by'] as num?)?.toInt(),
  grantedAt: json['granted_at'] as String?,
);

Map<String, dynamic> _$AclEntryRowToJson(_AclEntryRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'target_type': instance.targetType,
      'target_id': instance.targetId,
      'principal_type': instance.principalType,
      'principal_id': instance.principalId,
      'principal_name': instance.principalName,
      'permission_level': instance.permissionLevel,
      'granted_by': instance.grantedBy,
      'granted_at': instance.grantedAt,
    };
