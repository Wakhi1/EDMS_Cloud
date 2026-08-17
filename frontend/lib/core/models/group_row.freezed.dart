// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupRow {

 int get id; String get name; String? get description;@JsonKey(name: 'created_at') String? get createdAt; List<GroupMemberRow> get members;
/// Create a copy of GroupRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupRowCopyWith<GroupRow> get copyWith => _$GroupRowCopyWithImpl<GroupRow>(this as GroupRow, _$identity);

  /// Serializes this GroupRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupRow&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.members, members));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,createdAt,const DeepCollectionEquality().hash(members));

@override
String toString() {
  return 'GroupRow(id: $id, name: $name, description: $description, createdAt: $createdAt, members: $members)';
}


}

/// @nodoc
abstract mixin class $GroupRowCopyWith<$Res>  {
  factory $GroupRowCopyWith(GroupRow value, $Res Function(GroupRow) _then) = _$GroupRowCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? description,@JsonKey(name: 'created_at') String? createdAt, List<GroupMemberRow> members
});




}
/// @nodoc
class _$GroupRowCopyWithImpl<$Res>
    implements $GroupRowCopyWith<$Res> {
  _$GroupRowCopyWithImpl(this._self, this._then);

  final GroupRow _self;
  final $Res Function(GroupRow) _then;

/// Create a copy of GroupRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? createdAt = freezed,Object? members = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<GroupMemberRow>,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupRow].
extension GroupRowPatterns on GroupRow {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupRow() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupRow value)  $default,){
final _that = this;
switch (_that) {
case _GroupRow():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupRow value)?  $default,){
final _that = this;
switch (_that) {
case _GroupRow() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? description, @JsonKey(name: 'created_at')  String? createdAt,  List<GroupMemberRow> members)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupRow() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.createdAt,_that.members);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? description, @JsonKey(name: 'created_at')  String? createdAt,  List<GroupMemberRow> members)  $default,) {final _that = this;
switch (_that) {
case _GroupRow():
return $default(_that.id,_that.name,_that.description,_that.createdAt,_that.members);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? description, @JsonKey(name: 'created_at')  String? createdAt,  List<GroupMemberRow> members)?  $default,) {final _that = this;
switch (_that) {
case _GroupRow() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.createdAt,_that.members);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupRow implements GroupRow {
  const _GroupRow({required this.id, required this.name, this.description, @JsonKey(name: 'created_at') this.createdAt, final  List<GroupMemberRow> members = const <GroupMemberRow>[]}): _members = members;
  factory _GroupRow.fromJson(Map<String, dynamic> json) => _$GroupRowFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? description;
@override@JsonKey(name: 'created_at') final  String? createdAt;
 final  List<GroupMemberRow> _members;
@override@JsonKey() List<GroupMemberRow> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}


/// Create a copy of GroupRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupRowCopyWith<_GroupRow> get copyWith => __$GroupRowCopyWithImpl<_GroupRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupRow&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._members, _members));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,createdAt,const DeepCollectionEquality().hash(_members));

@override
String toString() {
  return 'GroupRow(id: $id, name: $name, description: $description, createdAt: $createdAt, members: $members)';
}


}

/// @nodoc
abstract mixin class _$GroupRowCopyWith<$Res> implements $GroupRowCopyWith<$Res> {
  factory _$GroupRowCopyWith(_GroupRow value, $Res Function(_GroupRow) _then) = __$GroupRowCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? description,@JsonKey(name: 'created_at') String? createdAt, List<GroupMemberRow> members
});




}
/// @nodoc
class __$GroupRowCopyWithImpl<$Res>
    implements _$GroupRowCopyWith<$Res> {
  __$GroupRowCopyWithImpl(this._self, this._then);

  final _GroupRow _self;
  final $Res Function(_GroupRow) _then;

/// Create a copy of GroupRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? createdAt = freezed,Object? members = null,}) {
  return _then(_GroupRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<GroupMemberRow>,
  ));
}


}

// dart format on
