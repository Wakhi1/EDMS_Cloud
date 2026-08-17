// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member_row.freezed.dart';
part 'group_member_row.g.dart';

/// A nested member row within GET /api/users/groups/all.
@freezed
abstract class GroupMemberRow with _$GroupMemberRow {
  const factory GroupMemberRow({
    required int id,
    @JsonKey(name: 'full_name') required String fullName,
  }) = _GroupMemberRow;

  factory GroupMemberRow.fromJson(Map<String, dynamic> json) => _$GroupMemberRowFromJson(json);
}
