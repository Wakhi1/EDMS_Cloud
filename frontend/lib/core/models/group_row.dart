// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import 'group_member_row.dart';

part 'group_row.freezed.dart';
part 'group_row.g.dart';

/// A row from GET /api/users/groups/all.
@freezed
abstract class GroupRow with _$GroupRow {
  const factory GroupRow({
    required int id,
    required String name,
    String? description,
    @JsonKey(name: 'created_at') String? createdAt,
    @Default(<GroupMemberRow>[]) List<GroupMemberRow> members,
  }) = _GroupRow;

  factory GroupRow.fromJson(Map<String, dynamic> json) => _$GroupRowFromJson(json);
}
