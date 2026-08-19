// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoleRow _$RoleRowFromJson(Map<String, dynamic> json) => _RoleRow(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  mfaRequired: _boolFromInt(json['mfa_required']),
  isSystemRole: _boolFromInt(json['is_system_role']),
);

Map<String, dynamic> _$RoleRowToJson(_RoleRow instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'mfa_required': instance.mfaRequired,
  'is_system_role': instance.isSystemRole,
};
