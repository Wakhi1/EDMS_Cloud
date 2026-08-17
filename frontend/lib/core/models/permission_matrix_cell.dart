// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_matrix_cell.freezed.dart';
part 'permission_matrix_cell.g.dart';

/// A row from GET /api/permissions/matrix/all.
@freezed
abstract class PermissionMatrixCell with _$PermissionMatrixCell {
  const factory PermissionMatrixCell({
    @JsonKey(name: 'role_id') required int roleId,
    required String module,
    @JsonKey(name: 'can_view', fromJson: _boolFromInt) required bool canView,
    @JsonKey(name: 'can_edit', fromJson: _boolFromInt) required bool canEdit,
    @JsonKey(name: 'role_name') String? roleName,
  }) = _PermissionMatrixCell;

  factory PermissionMatrixCell.fromJson(Map<String, dynamic> json) => _$PermissionMatrixCellFromJson(json);
}

bool _boolFromInt(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return false;
}
