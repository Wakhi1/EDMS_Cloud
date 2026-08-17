// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'acl_entry_row.freezed.dart';
part 'acl_entry_row.g.dart';

/// One row of `document_acl`, as returned in both the `own` and `inherited`
/// arrays of GET /api/permissions/:targetType/:targetId.
@freezed
abstract class AclEntryRow with _$AclEntryRow {
  const factory AclEntryRow({
    required int id,
    @JsonKey(name: 'target_type') required String targetType,
    @JsonKey(name: 'target_id') required int targetId,
    @JsonKey(name: 'principal_type') required String principalType,
    @JsonKey(name: 'principal_id') required int principalId,
    @JsonKey(name: 'principal_name') String? principalName,
    @JsonKey(name: 'permission_level') required String permissionLevel,
    @JsonKey(name: 'granted_by') int? grantedBy,
    @JsonKey(name: 'granted_at') String? grantedAt,
  }) = _AclEntryRow;

  factory AclEntryRow.fromJson(Map<String, dynamic> json) => _$AclEntryRowFromJson(json);
}
