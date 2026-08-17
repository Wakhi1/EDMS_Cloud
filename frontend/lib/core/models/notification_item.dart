// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_item.freezed.dart';
part 'notification_item.g.dart';

/// A notification row from GET /api/notifications (raw `notifications`
/// table row, no module gate — any authenticated user).
@freezed
abstract class NotificationItem with _$NotificationItem {
  const factory NotificationItem({
    required int id,
    required String type,
    required String title,
    String? body,
    @JsonKey(name: 'related_record_type') String? relatedRecordType,
    @JsonKey(name: 'related_record_id') String? relatedRecordId,
    @JsonKey(name: 'is_read', fromJson: _boolFromInt) required bool isRead,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _NotificationItem;

  factory NotificationItem.fromJson(Map<String, dynamic> json) => _$NotificationItemFromJson(json);
}

// MySQL TINYINT(1) booleans come back over mysql2/express-JSON as 0/1, not
// true/false — normalise both shapes since a JSON boolean is also valid.
bool _boolFromInt(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return false;
}
