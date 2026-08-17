// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log_row.freezed.dart';
part 'audit_log_row.g.dart';

/// A row from GET /api/audit.
@freezed
abstract class AuditLogRow with _$AuditLogRow {
  const factory AuditLogRow({
    required int id,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'user_name') String? userName,
    required String action,
    @JsonKey(name: 'record_type') String? recordType,
    @JsonKey(name: 'record_id') String? recordId,
    String? detail,
    @JsonKey(name: 'ip_address') String? ipAddress,
  }) = _AuditLogRow;

  factory AuditLogRow.fromJson(Map<String, dynamic> json) => _$AuditLogRowFromJson(json);
}
