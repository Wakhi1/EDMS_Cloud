// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'access_request_row.freezed.dart';
part 'access_request_row.g.dart';

/// A row from GET /api/access-requests (queue) or GET /api/access-requests/mine.
@freezed
abstract class AccessRequestRow with _$AccessRequestRow {
  const factory AccessRequestRow({
    required int id,
    @JsonKey(name: 'target_type') required String targetType,
    @JsonKey(name: 'target_id') required int targetId,
    @JsonKey(name: 'requested_level') required String requestedLevel,
    String? reason,
    @JsonKey(name: 'requester_id') required int requesterId,
    @JsonKey(name: 'requester_name') String? requesterName,
    required String status,
    @JsonKey(name: 'decided_by') int? decidedBy,
    @JsonKey(name: 'decided_by_name') String? decidedByName,
    @JsonKey(name: 'decided_at') String? decidedAt,
    @JsonKey(name: 'decision_note') String? decisionNote,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _AccessRequestRow;

  factory AccessRequestRow.fromJson(Map<String, dynamic> json) => _$AccessRequestRowFromJson(json);
}
