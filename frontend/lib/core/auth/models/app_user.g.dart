// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  id: (json['id'] as num).toInt(),
  fullName: json['fullName'] as String,
  email: json['email'] as String,
  role: json['role'] as String,
  roleId: (json['roleId'] as num?)?.toInt(),
  mfaSatisfied: json['mfaSatisfied'] as bool?,
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'fullName': instance.fullName,
  'email': instance.email,
  'role': instance.role,
  'roleId': instance.roleId,
  'mfaSatisfied': instance.mfaSatisfied,
};
