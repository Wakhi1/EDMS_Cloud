// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ocr_preview_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OcrPreviewResult _$OcrPreviewResultFromJson(
  Map<String, dynamic> json,
) => _OcrPreviewResult(
  text: json['text'] as String?,
  confidence: (json['confidence'] as num?)?.toInt(),
  suggestedDocumentTypeId: (json['suggestedDocumentTypeId'] as num?)?.toInt(),
  suggestedMemberNumber: json['suggestedMemberNumber'] as String?,
  duplicateOf: json['duplicateOf'] == null
      ? null
      : DuplicateOfInfo.fromJson(json['duplicateOf'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OcrPreviewResultToJson(_OcrPreviewResult instance) =>
    <String, dynamic>{
      'text': instance.text,
      'confidence': instance.confidence,
      'suggestedDocumentTypeId': instance.suggestedDocumentTypeId,
      'suggestedMemberNumber': instance.suggestedMemberNumber,
      'duplicateOf': instance.duplicateOf,
    };

_DuplicateOfInfo _$DuplicateOfInfoFromJson(Map<String, dynamic> json) =>
    _DuplicateOfInfo(
      id: (json['id'] as num).toInt(),
      recordNo: json['recordNo'] as String,
      title: json['title'] as String,
    );

Map<String, dynamic> _$DuplicateOfInfoToJson(_DuplicateOfInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'recordNo': instance.recordNo,
      'title': instance.title,
    };
