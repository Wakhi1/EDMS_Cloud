// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'department_row.freezed.dart';
part 'department_row.g.dart';

/// A row from GET /api/departments.
@freezed
abstract class DepartmentRow with _$DepartmentRow {
  const factory DepartmentRow({
    required int id,
    required String name,
    String? description,
    @JsonKey(name: 'is_active', fromJson: _boolFromInt) required bool isActive,
  }) = _DepartmentRow;

  factory DepartmentRow.fromJson(Map<String, dynamic> json) => _$DepartmentRowFromJson(json);
}

bool _boolFromInt(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return false;
}
