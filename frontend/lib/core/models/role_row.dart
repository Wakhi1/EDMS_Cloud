// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'role_row.freezed.dart';
part 'role_row.g.dart';

/// A row from GET /api/roles.
@freezed
abstract class RoleRow with _$RoleRow {
  const factory RoleRow({
    required int id,
    required String name,
    String? description,
    @JsonKey(name: 'mfa_required', fromJson: _boolFromInt) required bool mfaRequired,
    @JsonKey(name: 'is_system_role', fromJson: _boolFromInt) required bool isSystemRole,
  }) = _RoleRow;

  factory RoleRow.fromJson(Map<String, dynamic> json) => _$RoleRowFromJson(json);
}

bool _boolFromInt(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return false;
}
