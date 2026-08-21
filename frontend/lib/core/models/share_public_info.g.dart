// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_public_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SharePublicInfo _$SharePublicInfoFromJson(Map<String, dynamic> json) =>
    _SharePublicInfo(
      recordNo: json['record_no'] as String,
      title: json['title'] as String,
      classification: json['classification'] as String,
      expiresAt: json['expires_at'] as String,
    );

Map<String, dynamic> _$SharePublicInfoToJson(_SharePublicInfo instance) =>
    <String, dynamic>{
      'record_no': instance.recordNo,
      'title': instance.title,
      'classification': instance.classification,
      'expires_at': instance.expiresAt,
    };
