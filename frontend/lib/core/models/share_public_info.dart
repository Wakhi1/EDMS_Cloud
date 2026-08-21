// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'share_public_info.freezed.dart';
part 'share_public_info.g.dart';

/// GET /api/sharing/public/:token — what an unauthenticated recipient's
/// landing page (the /s/:token route) shows before they download.
@freezed
abstract class SharePublicInfo with _$SharePublicInfo {
  const factory SharePublicInfo({
    @JsonKey(name: 'record_no') required String recordNo,
    required String title,
    required String classification,
    @JsonKey(name: 'expires_at') required String expiresAt,
  }) = _SharePublicInfo;

  factory SharePublicInfo.fromJson(Map<String, dynamic> json) => _$SharePublicInfoFromJson(json);
}
