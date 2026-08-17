// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'department_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DepartmentRow _$DepartmentRowFromJson(Map<String, dynamic> json) =>
    _DepartmentRow(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: _boolFromInt(json['is_active']),
    );

Map<String, dynamic> _$DepartmentRowToJson(_DepartmentRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'is_active': instance.isActive,
    };
