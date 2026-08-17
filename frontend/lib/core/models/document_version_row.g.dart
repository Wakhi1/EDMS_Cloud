// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_version_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DocumentVersionRow _$DocumentVersionRowFromJson(Map<String, dynamic> json) =>
    _DocumentVersionRow(
      id: (json['id'] as num).toInt(),
      versionNo: (json['version_no'] as num).toInt(),
      fileName: json['file_name'] as String,
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      isCurrent: _boolFromInt(json['is_current']),
      createdAt: json['created_at'] as String?,
      createdBy: json['created_by'] as String?,
    );

Map<String, dynamic> _$DocumentVersionRowToJson(_DocumentVersionRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version_no': instance.versionNo,
      'file_name': instance.fileName,
      'size_bytes': instance.sizeBytes,
      'is_current': instance.isCurrent,
      'created_at': instance.createdAt,
      'created_by': instance.createdBy,
    };
