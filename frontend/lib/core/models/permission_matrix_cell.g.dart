// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_matrix_cell.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PermissionMatrixCell _$PermissionMatrixCellFromJson(
  Map<String, dynamic> json,
) => _PermissionMatrixCell(
  roleId: (json['role_id'] as num).toInt(),
  module: json['module'] as String,
  canView: _boolFromInt(json['can_view']),
  canEdit: _boolFromInt(json['can_edit']),
  roleName: json['role_name'] as String?,
);

Map<String, dynamic> _$PermissionMatrixCellToJson(
  _PermissionMatrixCell instance,
) => <String, dynamic>{
  'role_id': instance.roleId,
  'module': instance.module,
  'can_view': instance.canView,
  'can_edit': instance.canEdit,
  'role_name': instance.roleName,
};
