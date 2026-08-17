// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'retention_class_row.freezed.dart';
part 'retention_class_row.g.dart';

/// A row from GET /api/retention/classes.
@freezed
abstract class RetentionClassRow with _$RetentionClassRow {
  const factory RetentionClassRow({
    required int id,
    required String code,
    required String name,
    @JsonKey(name: 'retention_years') required int retentionYears,
    @JsonKey(name: 'trigger_event') String? triggerEvent,
    @JsonKey(name: 'disposal_action') required String disposalAction,
    @JsonKey(name: 'requires_records_manager_approval', fromJson: _boolFromInt)
    required bool requiresRecordsManagerApproval,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _RetentionClassRow;

  factory RetentionClassRow.fromJson(Map<String, dynamic> json) => _$RetentionClassRowFromJson(json);
}

bool _boolFromInt(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return false;
}
