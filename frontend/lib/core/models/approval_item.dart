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
  }) = _ApprovalItem;

  factory ApprovalItem.fromJson(Map<String, dynamic> json) => _$ApprovalItemFromJson(json);
}
