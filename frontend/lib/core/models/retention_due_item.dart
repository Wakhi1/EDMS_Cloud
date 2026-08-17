// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'retention_due_item.freezed.dart';
part 'retention_due_item.g.dart';

/// A row from GET /api/retention/due.
@freezed
abstract class RetentionDueItem with _$RetentionDueItem {
  const factory RetentionDueItem({
    required int id,
    @JsonKey(name: 'record_no') required String recordNo,
    required String title,
    @JsonKey(name: 'retention_due_at') required String retentionDueAt,
    @JsonKey(name: 'disposal_action') required String disposalAction,
    @JsonKey(name: 'retention_class_name') String? retentionClassName,
  }) = _RetentionDueItem;

  factory RetentionDueItem.fromJson(Map<String, dynamic> json) => _$RetentionDueItemFromJson(json);
}
