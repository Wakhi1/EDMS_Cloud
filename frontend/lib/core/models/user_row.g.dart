// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserRow _$UserRowFromJson(Map<String, dynamic> json) => _UserRow(
  id: (json['id'] as num).toInt(),
  fullName: json['full_name'] as String,
  email: json['email'] as String,
  phoneNumber: json['phone_number'] as String?,
  isActive: _boolFromInt(json['is_active']),
  isLocked: _boolFromInt(json['is_locked']),
  mfaEnabled: _boolFromInt(json['mfa_enabled']),
  roleName: json['role_name'] as String,
  departmentId: (json['department_id'] as num?)?.toInt(),
  departmentName: json['department_name'] as String?,
  adLinked: json['ad_linked'] == null ? false : _boolFromInt(json['ad_linked']),
);

Map<String, dynamic> _$UserRowToJson(_UserRow instance) => <String, dynamic>{
  'id': instance.id,
  'full_name': instance.fullName,
  'email': instance.email,
  'phone_number': instance.phoneNumber,
  'is_active': instance.isActive,
  'is_locked': instance.isLocked,
  'mfa_enabled': instance.mfaEnabled,
  'role_name': instance.roleName,
  'department_id': instance.departmentId,
  'department_name': instance.departmentName,
  'ad_linked': instance.adLinked,
};
