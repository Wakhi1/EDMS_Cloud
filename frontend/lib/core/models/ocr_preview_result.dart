import 'package:freezed_annotation/freezed_annotation.dart';

part 'ocr_preview_result.freezed.dart';
part 'ocr_preview_result.g.dart';

/// Response of POST /api/documents/ocr-preview — stateless, nothing is
/// persisted server-side for this call. Backend returns camelCase keys
/// directly (no snake_case mapping needed here, unlike most other models).
@freezed
abstract class OcrPreviewResult with _$OcrPreviewResult {
  const factory OcrPreviewResult({
    String? text,
    int? confidence,
    int? suggestedDocumentTypeId,
    String? suggestedMemberNumber,
    DuplicateOfInfo? duplicateOf,
  }) = _OcrPreviewResult;

  factory OcrPreviewResult.fromJson(Map<String, dynamic> json) => _$OcrPreviewResultFromJson(json);
}

/// The existing live document a file's content hash already matches, if
/// any — see document.service.js's findDuplicateByContentHash.
@freezed
abstract class DuplicateOfInfo with _$DuplicateOfInfo {
  const factory DuplicateOfInfo({
    required int id,
    required String recordNo,
    required String title,
  }) = _DuplicateOfInfo;

  factory DuplicateOfInfo.fromJson(Map<String, dynamic> json) => _$DuplicateOfInfoFromJson(json);
}
