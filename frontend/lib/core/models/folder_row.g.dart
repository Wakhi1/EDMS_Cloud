// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FolderRow _$FolderRowFromJson(Map<String, dynamic> json) => _FolderRow(
  id: (json['id'] as num).toInt(),
  parentId: (json['parent_id'] as num?)?.toInt(),
  name: json['name'] as String,
  path: json['path'] as String,
  departmentId: (json['department_id'] as num?)?.toInt(),
  retentionClassId: (json['retention_class_id'] as num?)?.toInt(),
  retentionClassName: json['retention_class_name'] as String?,
  storageProviders: json['storage_providers'] as String?,
);

Map<String, dynamic> _$FolderRowToJson(_FolderRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parent_id': instance.parentId,
      'name': instance.name,
      'path': instance.path,
      'department_id': instance.departmentId,
      'retention_class_id': instance.retentionClassId,
      'retention_class_name': instance.retentionClassName,
      'storage_providers': instance.storageProviders,
    };
