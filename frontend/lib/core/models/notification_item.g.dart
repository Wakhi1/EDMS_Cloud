// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationItem _$NotificationItemFromJson(Map<String, dynamic> json) =>
    _NotificationItem(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      relatedRecordType: json['related_record_type'] as String?,
      relatedRecordId: json['related_record_id'] as String?,
      isRead: _boolFromInt(json['is_read']),
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$NotificationItemToJson(_NotificationItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'body': instance.body,
      'related_record_type': instance.relatedRecordType,
      'related_record_id': instance.relatedRecordId,
      'is_read': instance.isRead,
      'created_at': instance.createdAt,
    };
