// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'share_link.freezed.dart';
part 'share_link.g.dart';

/// A row from GET /api/sharing.
@freezed
abstract class ShareLink with _$ShareLink {
  const factory ShareLink({
    required int id,
    required String token,
    @JsonKey(name: 'expires_at') required String expiresAt,
    @JsonKey(name: 'revoked_at') String? revokedAt,
    @JsonKey(name: 'access_count') required int accessCount,
    @JsonKey(name: 'last_accessed_at') String? lastAccessedAt,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'document_id') required int documentId,
    @JsonKey(name: 'record_no') required String recordNo,
    required String title,
    @JsonKey(name: 'created_by_name') String? createdByName,
  }) = _ShareLink;

  factory ShareLink.fromJson(Map<String, dynamic> json) => _$ShareLinkFromJson(json);
}

extension ShareLinkStatus on ShareLink {
  bool get isRevoked => revokedAt != null;
  bool get isExpired => DateTime.tryParse(expiresAt)?.isBefore(DateTime.now()) ?? false;
  bool get isActive => !isRevoked && !isExpired;
}
