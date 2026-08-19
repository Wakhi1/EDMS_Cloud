// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'role_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoleRow {

 int get id; String get name; String? get description;@JsonKey(name: 'mfa_required', fromJson: _boolFromInt) bool get mfaRequired;@JsonKey(name: 'is_system_role', fromJson: _boolFromInt) bool get isSystemRole;
/// Create a copy of RoleRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoleRowCopyWith<RoleRow> get copyWith => _$RoleRowCopyWithImpl<RoleRow>(this as RoleRow, _$identity);

  /// Serializes this RoleRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoleRow&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.mfaRequired, mfaRequired) || other.mfaRequired == mfaRequired)&&(identical(other.isSystemRole, isSystemRole) || other.isSystemRole == isSystemRole));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,mfaRequired,isSystemRole);

@override
String toString() {
  return 'RoleRow(id: $id, name: $name, description: $description, mfaRequired: $mfaRequired, isSystemRole: $isSystemRole)';
}


}

/// @nodoc
abstract mixin class $RoleRowCopyWith<$Res>  {
  factory $RoleRowCopyWith(RoleRow value, $Res Function(RoleRow) _then) = _$RoleRowCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? description,@JsonKey(name: 'mfa_required', fromJson: _boolFromInt) bool mfaRequired,@JsonKey(name: 'is_system_role', fromJson: _boolFromInt) bool isSystemRole
});




}
/// @nodoc
class _$RoleRowCopyWithImpl<$Res>
    implements $RoleRowCopyWith<$Res> {
  _$RoleRowCopyWithImpl(this._self, this._then);

  final RoleRow _self;
  final $Res Function(RoleRow) _then;

/// Create a copy of RoleRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? mfaRequired = null,Object? isSystemRole = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,mfaRequired: null == mfaRequired ? _self.mfaRequired : mfaRequired // ignore: cast_nullable_to_non_nullable
as bool,isSystemRole: null == isSystemRole ? _self.isSystemRole : isSystemRole // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RoleRow].
extension RoleRowPatterns on RoleRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoleRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoleRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoleRow value)  $default,){
final _that = this;
switch (_that) {
case _RoleRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoleRow value)?  $default,){
final _that = this;
switch (_that) {
case _RoleRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? description, @JsonKey(name: 'mfa_required', fromJson: _boolFromInt)  bool mfaRequired, @JsonKey(name: 'is_system_role', fromJson: _boolFromInt)  bool isSystemRole)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoleRow() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.mfaRequired,_that.isSystemRole);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? description, @JsonKey(name: 'mfa_required', fromJson: _boolFromInt)  bool mfaRequired, @JsonKey(name: 'is_system_role', fromJson: _boolFromInt)  bool isSystemRole)  $default,) {final _that = this;
switch (_that) {
case _RoleRow():
return $default(_that.id,_that.name,_that.description,_that.mfaRequired,_that.isSystemRole);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? description, @JsonKey(name: 'mfa_required', fromJson: _boolFromInt)  bool mfaRequired, @JsonKey(name: 'is_system_role', fromJson: _boolFromInt)  bool isSystemRole)?  $default,) {final _that = this;
switch (_that) {
case _RoleRow() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.mfaRequired,_that.isSystemRole);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoleRow implements RoleRow {
  const _RoleRow({required this.id, required this.name, this.description, @JsonKey(name: 'mfa_required', fromJson: _boolFromInt) required this.mfaRequired, @JsonKey(name: 'is_system_role', fromJson: _boolFromInt) required this.isSystemRole});
  factory _RoleRow.fromJson(Map<String, dynamic> json) => _$RoleRowFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? description;
@override@JsonKey(name: 'mfa_required', fromJson: _boolFromInt) final  bool mfaRequired;
@override@JsonKey(name: 'is_system_role', fromJson: _boolFromInt) final  bool isSystemRole;

/// Create a copy of RoleRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoleRowCopyWith<_RoleRow> get copyWith => __$RoleRowCopyWithImpl<_RoleRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoleRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoleRow&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.mfaRequired, mfaRequired) || other.mfaRequired == mfaRequired)&&(identical(other.isSystemRole, isSystemRole) || other.isSystemRole == isSystemRole));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,mfaRequired,isSystemRole);

@override
String toString() {
  return 'RoleRow(id: $id, name: $name, description: $description, mfaRequired: $mfaRequired, isSystemRole: $isSystemRole)';
}


}

/// @nodoc
abstract mixin class _$RoleRowCopyWith<$Res> implements $RoleRowCopyWith<$Res> {
  factory _$RoleRowCopyWith(_RoleRow value, $Res Function(_RoleRow) _then) = __$RoleRowCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? description,@JsonKey(name: 'mfa_required', fromJson: _boolFromInt) bool mfaRequired,@JsonKey(name: 'is_system_role', fromJson: _boolFromInt) bool isSystemRole
});




}
/// @nodoc
class __$RoleRowCopyWithImpl<$Res>
    implements _$RoleRowCopyWith<$Res> {
  __$RoleRowCopyWithImpl(this._self, this._then);

  final _RoleRow _self;
  final $Res Function(_RoleRow) _then;

/// Create a copy of RoleRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? mfaRequired = null,Object? isSystemRole = null,}) {
  return _then(_RoleRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,mfaRequired: null == mfaRequired ? _self.mfaRequired : mfaRequired // ignore: cast_nullable_to_non_nullable
as bool,isSystemRole: null == isSystemRole ? _self.isSystemRole : isSystemRole // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
