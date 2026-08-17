// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'acl_entry_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AclEntryRow {

 int get id;@JsonKey(name: 'target_type') String get targetType;@JsonKey(name: 'target_id') int get targetId;@JsonKey(name: 'principal_type') String get principalType;@JsonKey(name: 'principal_id') int get principalId;@JsonKey(name: 'principal_name') String? get principalName;@JsonKey(name: 'permission_level') String get permissionLevel;@JsonKey(name: 'granted_by') int? get grantedBy;@JsonKey(name: 'granted_at') String? get grantedAt;
/// Create a copy of AclEntryRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AclEntryRowCopyWith<AclEntryRow> get copyWith => _$AclEntryRowCopyWithImpl<AclEntryRow>(this as AclEntryRow, _$identity);

  /// Serializes this AclEntryRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AclEntryRow&&(identical(other.id, id) || other.id == id)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.principalType, principalType) || other.principalType == principalType)&&(identical(other.principalId, principalId) || other.principalId == principalId)&&(identical(other.principalName, principalName) || other.principalName == principalName)&&(identical(other.permissionLevel, permissionLevel) || other.permissionLevel == permissionLevel)&&(identical(other.grantedBy, grantedBy) || other.grantedBy == grantedBy)&&(identical(other.grantedAt, grantedAt) || other.grantedAt == grantedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,targetType,targetId,principalType,principalId,principalName,permissionLevel,grantedBy,grantedAt);

@override
String toString() {
  return 'AclEntryRow(id: $id, targetType: $targetType, targetId: $targetId, principalType: $principalType, principalId: $principalId, principalName: $principalName, permissionLevel: $permissionLevel, grantedBy: $grantedBy, grantedAt: $grantedAt)';
}


}

/// @nodoc
abstract mixin class $AclEntryRowCopyWith<$Res>  {
  factory $AclEntryRowCopyWith(AclEntryRow value, $Res Function(AclEntryRow) _then) = _$AclEntryRowCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'target_type') String targetType,@JsonKey(name: 'target_id') int targetId,@JsonKey(name: 'principal_type') String principalType,@JsonKey(name: 'principal_id') int principalId,@JsonKey(name: 'principal_name') String? principalName,@JsonKey(name: 'permission_level') String permissionLevel,@JsonKey(name: 'granted_by') int? grantedBy,@JsonKey(name: 'granted_at') String? grantedAt
});




}
/// @nodoc
class _$AclEntryRowCopyWithImpl<$Res>
    implements $AclEntryRowCopyWith<$Res> {
  _$AclEntryRowCopyWithImpl(this._self, this._then);

  final AclEntryRow _self;
  final $Res Function(AclEntryRow) _then;

/// Create a copy of AclEntryRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? targetType = null,Object? targetId = null,Object? principalType = null,Object? principalId = null,Object? principalName = freezed,Object? permissionLevel = null,Object? grantedBy = freezed,Object? grantedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as int,principalType: null == principalType ? _self.principalType : principalType // ignore: cast_nullable_to_non_nullable
as String,principalId: null == principalId ? _self.principalId : principalId // ignore: cast_nullable_to_non_nullable
as int,principalName: freezed == principalName ? _self.principalName : principalName // ignore: cast_nullable_to_non_nullable
as String?,permissionLevel: null == permissionLevel ? _self.permissionLevel : permissionLevel // ignore: cast_nullable_to_non_nullable
as String,grantedBy: freezed == grantedBy ? _self.grantedBy : grantedBy // ignore: cast_nullable_to_non_nullable
as int?,grantedAt: freezed == grantedAt ? _self.grantedAt : grantedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AclEntryRow].
extension AclEntryRowPatterns on AclEntryRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AclEntryRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AclEntryRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AclEntryRow value)  $default,){
final _that = this;
switch (_that) {
case _AclEntryRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AclEntryRow value)?  $default,){
final _that = this;
switch (_that) {
case _AclEntryRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'target_type')  String targetType, @JsonKey(name: 'target_id')  int targetId, @JsonKey(name: 'principal_type')  String principalType, @JsonKey(name: 'principal_id')  int principalId, @JsonKey(name: 'principal_name')  String? principalName, @JsonKey(name: 'permission_level')  String permissionLevel, @JsonKey(name: 'granted_by')  int? grantedBy, @JsonKey(name: 'granted_at')  String? grantedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AclEntryRow() when $default != null:
return $default(_that.id,_that.targetType,_that.targetId,_that.principalType,_that.principalId,_that.principalName,_that.permissionLevel,_that.grantedBy,_that.grantedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'target_type')  String targetType, @JsonKey(name: 'target_id')  int targetId, @JsonKey(name: 'principal_type')  String principalType, @JsonKey(name: 'principal_id')  int principalId, @JsonKey(name: 'principal_name')  String? principalName, @JsonKey(name: 'permission_level')  String permissionLevel, @JsonKey(name: 'granted_by')  int? grantedBy, @JsonKey(name: 'granted_at')  String? grantedAt)  $default,) {final _that = this;
switch (_that) {
case _AclEntryRow():
return $default(_that.id,_that.targetType,_that.targetId,_that.principalType,_that.principalId,_that.principalName,_that.permissionLevel,_that.grantedBy,_that.grantedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'target_type')  String targetType, @JsonKey(name: 'target_id')  int targetId, @JsonKey(name: 'principal_type')  String principalType, @JsonKey(name: 'principal_id')  int principalId, @JsonKey(name: 'principal_name')  String? principalName, @JsonKey(name: 'permission_level')  String permissionLevel, @JsonKey(name: 'granted_by')  int? grantedBy, @JsonKey(name: 'granted_at')  String? grantedAt)?  $default,) {final _that = this;
switch (_that) {
case _AclEntryRow() when $default != null:
return $default(_that.id,_that.targetType,_that.targetId,_that.principalType,_that.principalId,_that.principalName,_that.permissionLevel,_that.grantedBy,_that.grantedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AclEntryRow implements AclEntryRow {
  const _AclEntryRow({required this.id, @JsonKey(name: 'target_type') required this.targetType, @JsonKey(name: 'target_id') required this.targetId, @JsonKey(name: 'principal_type') required this.principalType, @JsonKey(name: 'principal_id') required this.principalId, @JsonKey(name: 'principal_name') this.principalName, @JsonKey(name: 'permission_level') required this.permissionLevel, @JsonKey(name: 'granted_by') this.grantedBy, @JsonKey(name: 'granted_at') this.grantedAt});
  factory _AclEntryRow.fromJson(Map<String, dynamic> json) => _$AclEntryRowFromJson(json);

@override final  int id;
@override@JsonKey(name: 'target_type') final  String targetType;
@override@JsonKey(name: 'target_id') final  int targetId;
@override@JsonKey(name: 'principal_type') final  String principalType;
@override@JsonKey(name: 'principal_id') final  int principalId;
@override@JsonKey(name: 'principal_name') final  String? principalName;
@override@JsonKey(name: 'permission_level') final  String permissionLevel;
@override@JsonKey(name: 'granted_by') final  int? grantedBy;
@override@JsonKey(name: 'granted_at') final  String? grantedAt;

/// Create a copy of AclEntryRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AclEntryRowCopyWith<_AclEntryRow> get copyWith => __$AclEntryRowCopyWithImpl<_AclEntryRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AclEntryRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AclEntryRow&&(identical(other.id, id) || other.id == id)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.principalType, principalType) || other.principalType == principalType)&&(identical(other.principalId, principalId) || other.principalId == principalId)&&(identical(other.principalName, principalName) || other.principalName == principalName)&&(identical(other.permissionLevel, permissionLevel) || other.permissionLevel == permissionLevel)&&(identical(other.grantedBy, grantedBy) || other.grantedBy == grantedBy)&&(identical(other.grantedAt, grantedAt) || other.grantedAt == grantedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,targetType,targetId,principalType,principalId,principalName,permissionLevel,grantedBy,grantedAt);

@override
String toString() {
  return 'AclEntryRow(id: $id, targetType: $targetType, targetId: $targetId, principalType: $principalType, principalId: $principalId, principalName: $principalName, permissionLevel: $permissionLevel, grantedBy: $grantedBy, grantedAt: $grantedAt)';
}


}

/// @nodoc
abstract mixin class _$AclEntryRowCopyWith<$Res> implements $AclEntryRowCopyWith<$Res> {
  factory _$AclEntryRowCopyWith(_AclEntryRow value, $Res Function(_AclEntryRow) _then) = __$AclEntryRowCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'target_type') String targetType,@JsonKey(name: 'target_id') int targetId,@JsonKey(name: 'principal_type') String principalType,@JsonKey(name: 'principal_id') int principalId,@JsonKey(name: 'principal_name') String? principalName,@JsonKey(name: 'permission_level') String permissionLevel,@JsonKey(name: 'granted_by') int? grantedBy,@JsonKey(name: 'granted_at') String? grantedAt
});




}
/// @nodoc
class __$AclEntryRowCopyWithImpl<$Res>
    implements _$AclEntryRowCopyWith<$Res> {
  __$AclEntryRowCopyWithImpl(this._self, this._then);

  final _AclEntryRow _self;
  final $Res Function(_AclEntryRow) _then;

/// Create a copy of AclEntryRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? targetType = null,Object? targetId = null,Object? principalType = null,Object? principalId = null,Object? principalName = freezed,Object? permissionLevel = null,Object? grantedBy = freezed,Object? grantedAt = freezed,}) {
  return _then(_AclEntryRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as int,principalType: null == principalType ? _self.principalType : principalType // ignore: cast_nullable_to_non_nullable
as String,principalId: null == principalId ? _self.principalId : principalId // ignore: cast_nullable_to_non_nullable
as int,principalName: freezed == principalName ? _self.principalName : principalName // ignore: cast_nullable_to_non_nullable
as String?,permissionLevel: null == permissionLevel ? _self.permissionLevel : permissionLevel // ignore: cast_nullable_to_non_nullable
as String,grantedBy: freezed == grantedBy ? _self.grantedBy : grantedBy // ignore: cast_nullable_to_non_nullable
as int?,grantedAt: freezed == grantedAt ? _self.grantedAt : grantedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
