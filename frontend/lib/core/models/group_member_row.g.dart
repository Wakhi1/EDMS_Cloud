// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupMemberRow _$GroupMemberRowFromJson(Map<String, dynamic> json) =>
    _GroupMemberRow(
      id: (json['id'] as num).toInt(),
      fullName: json['full_name'] as String,
    );

Map<String, dynamic> _$GroupMemberRowToJson(_GroupMemberRow instance) =>
    <String, dynamic>{'id': instance.id, 'full_name': instance.fullName};
