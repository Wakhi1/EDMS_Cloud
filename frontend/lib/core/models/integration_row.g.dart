// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integration_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IntegrationRow _$IntegrationRowFromJson(Map<String, dynamic> json) =>
    _IntegrationRow(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      endpoint: json['endpoint'] as String?,
      status: json['status'] as String,
      lastSyncAt: json['last_sync_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      configJson: _configJsonFromJson(json['config_json']),
    );

Map<String, dynamic> _$IntegrationRowToJson(_IntegrationRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'endpoint': instance.endpoint,
      'status': instance.status,
      'last_sync_at': instance.lastSyncAt,
      'updated_at': instance.updatedAt,
      'config_json': instance.configJson,
    };
