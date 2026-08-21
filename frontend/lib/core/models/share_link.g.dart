// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShareLink _$ShareLinkFromJson(Map<String, dynamic> json) => _ShareLink(
  id: (json['id'] as num).toInt(),
  token: json['token'] as String,
  expiresAt: json['expires_at'] as String,
  revokedAt: json['revoked_at'] as String?,
  accessCount: (json['access_count'] as num).toInt(),
  lastAccessedAt: json['last_accessed_at'] as String?,
  createdAt: json['created_at'] as String,
  documentId: (json['document_id'] as num).toInt(),
  recordNo: json['record_no'] as String,
  title: json['title'] as String,
  createdByName: json['created_by_name'] as String?,
);

Map<String, dynamic> _$ShareLinkToJson(_ShareLink instance) =>
    <String, dynamic>{
      'id': instance.id,
      'token': instance.token,
      'expires_at': instance.expiresAt,
      'revoked_at': instance.revokedAt,
      'access_count': instance.accessCount,
      'last_accessed_at': instance.lastAccessedAt,
      'created_at': instance.createdAt,
      'document_id': instance.documentId,
      'record_no': instance.recordNo,
      'title': instance.title,
      'created_by_name': instance.createdByName,
    };
