// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupRow _$GroupRowFromJson(Map<String, dynamic> json) => _GroupRow(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  createdAt: json['created_at'] as String?,
  members:
      (json['members'] as List<dynamic>?)
          ?.map((e) => GroupMemberRow.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <GroupMemberRow>[],
);

Map<String, dynamic> _$GroupRowToJson(_GroupRow instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'created_at': instance.createdAt,
  'members': instance.members,
};
