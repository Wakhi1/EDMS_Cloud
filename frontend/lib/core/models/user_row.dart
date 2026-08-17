// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_row.freezed.dart';
part 'user_row.g.dart';

/// A row from GET /api/users.
@freezed
abstract class UserRow with _$UserRow {
  const factory UserRow({
    required int id,
    @JsonKey(name: 'full_name') required String fullName,
    required String email,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    @JsonKey(name: 'is_active', fromJson: _boolFromInt) required bool isActive,
    @JsonKey(name: 'is_locked', fromJson: _boolFromInt) required bool isLocked,
    @JsonKey(name: 'mfa_enabled', fromJson: _boolFromInt) required bool mfaEnabled,
    @JsonKey(name: 'role_name') required String roleName,
    @JsonKey(name: 'department_id') int? departmentId,
    @JsonKey(name: 'department_name') String? departmentName,
    @JsonKey(name: 'ad_linked', fromJson: _boolFromInt) @Default(false) bool adLinked,
  }) = _UserRow;

  factory UserRow.fromJson(Map<String, dynamic> json) => _$UserRowFromJson(json);
}

bool _boolFromInt(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return false;
}
