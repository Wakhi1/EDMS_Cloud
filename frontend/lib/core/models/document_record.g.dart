// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DocumentRecord _$DocumentRecordFromJson(Map<String, dynamic> json) =>
    _DocumentRecord(
      id: (json['id'] as num).toInt(),
      recordNo: json['record_no'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      classification: json['classification'] as String,
      memberNumber: json['member_number'] as String?,
      memberName: json['member_name'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      documentType: json['document_type'] as String?,
      department: json['department'] as String?,
      folderPath: json['folder_path'] as String?,
      currentVersionNo: (json['current_version_no'] as num?)?.toInt(),
      ownerName: json['owner_name'] as String?,
      mimeType: json['mime_type'] as String?,
      fileName: json['file_name'] as String?,
      sizeBytes: _intFromDynamic(json['size_bytes']),
      storageProvider: json['storage_provider'] as String?,
    );

Map<String, dynamic> _$DocumentRecordToJson(_DocumentRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'record_no': instance.recordNo,
      'title': instance.title,
      'status': instance.status,
      'classification': instance.classification,
      'member_number': instance.memberNumber,
      'member_name': instance.memberName,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'document_type': instance.documentType,
      'department': instance.department,
      'folder_path': instance.folderPath,
      'current_version_no': instance.currentVersionNo,
      'owner_name': instance.ownerName,
      'mime_type': instance.mimeType,
      'file_name': instance.fileName,
      'size_bytes': instance.sizeBytes,
      'storage_provider': instance.storageProvider,
    };
