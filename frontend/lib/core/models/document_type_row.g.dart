// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_type_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DocumentTypeRow _$DocumentTypeRowFromJson(Map<String, dynamic> json) =>
    _DocumentTypeRow(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      code: json['code'] as String,
    );

Map<String, dynamic> _$DocumentTypeRowToJson(_DocumentTypeRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
    };
