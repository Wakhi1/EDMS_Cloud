// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'approval_item.freezed.dart';
part 'approval_item.g.dart';

/// A pending approval-inbox row from GET /api/approvals.
@freezed
abstract class ApprovalItem with _$ApprovalItem {
  const factory ApprovalItem({
    @JsonKey(name: 'approval_id') required int approvalId,
    @JsonKey(name: 'instance_id') required int instanceId,
    @JsonKey(name: 'step_id') required int stepId,
    @JsonKey(name: 'document_id') required int documentId,
    @JsonKey(name: 'record_no') required String recordNo,
    required String title,
    @JsonKey(name: 'step_name') required String stepName,
    @JsonKey(name: 'sla_days') int? slaDays,
    @JsonKey(name: 'started_at') String? startedAt,
    @JsonKey(name: 'escalated_at') String? escalatedAt,
    @JsonKey(name: 'requires_signature', fromJson: _boolFromInt) @Default(false) bool requiresSignature,
  }) = _ApprovalItem;

  factory ApprovalItem.fromJson(Map<String, dynamic> json) => _$ApprovalItemFromJson(json);
}

bool _boolFromInt(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return false;
}
