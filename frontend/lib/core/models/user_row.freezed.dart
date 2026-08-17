// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserRow {

 int get id;@JsonKey(name: 'full_name') String get fullName; String get email;@JsonKey(name: 'phone_number') String? get phoneNumber;@JsonKey(name: 'is_active', fromJson: _boolFromInt) bool get isActive;@JsonKey(name: 'is_locked', fromJson: _boolFromInt) bool get isLocked;@JsonKey(name: 'mfa_enabled', fromJson: _boolFromInt) bool get mfaEnabled;@JsonKey(name: 'role_name') String get roleName;@JsonKey(name: 'department_id') int? get departmentId;@JsonKey(name: 'department_name') String? get departmentName;@JsonKey(name: 'ad_linked', fromJson: _boolFromInt) bool get adLinked;
/// Create a copy of UserRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserRowCopyWith<UserRow> get copyWith => _$UserRowCopyWithImpl<UserRow>(this as UserRow, _$identity);

  /// Serializes this UserRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserRow&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.mfaEnabled, mfaEnabled) || other.mfaEnabled == mfaEnabled)&&(identical(other.roleName, roleName) || other.roleName == roleName)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.departmentName, departmentName) || other.departmentName == departmentName)&&(identical(other.adLinked, adLinked) || other.adLinked == adLinked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,email,phoneNumber,isActive,isLocked,mfaEnabled,roleName,departmentId,departmentName,adLinked);

@override
String toString() {
  return 'UserRow(id: $id, fullName: $fullName, email: $email, phoneNumber: $phoneNumber, isActive: $isActive, isLocked: $isLocked, mfaEnabled: $mfaEnabled, roleName: $roleName, departmentId: $departmentId, departmentName: $departmentName, adLinked: $adLinked)';
}


}

/// @nodoc
abstract mixin class $UserRowCopyWith<$Res>  {
  factory $UserRowCopyWith(UserRow value, $Res Function(UserRow) _then) = _$UserRowCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'full_name') String fullName, String email,@JsonKey(name: 'phone_number') String? phoneNumber,@JsonKey(name: 'is_active', fromJson: _boolFromInt) bool isActive,@JsonKey(name: 'is_locked', fromJson: _boolFromInt) bool isLocked,@JsonKey(name: 'mfa_enabled', fromJson: _boolFromInt) bool mfaEnabled,@JsonKey(name: 'role_name') String roleName,@JsonKey(name: 'department_id') int? departmentId,@JsonKey(name: 'department_name') String? departmentName,@JsonKey(name: 'ad_linked', fromJson: _boolFromInt) bool adLinked
});




}
/// @nodoc
class _$UserRowCopyWithImpl<$Res>
    implements $UserRowCopyWith<$Res> {
  _$UserRowCopyWithImpl(this._self, this._then);

  final UserRow _self;
  final $Res Function(UserRow) _then;

/// Create a copy of UserRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? email = null,Object? phoneNumber = freezed,Object? isActive = null,Object? isLocked = null,Object? mfaEnabled = null,Object? roleName = null,Object? departmentId = freezed,Object? departmentName = freezed,Object? adLinked = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,mfaEnabled: null == mfaEnabled ? _self.mfaEnabled : mfaEnabled // ignore: cast_nullable_to_non_nullable
as bool,roleName: null == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as String,departmentId: freezed == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as int?,departmentName: freezed == departmentName ? _self.departmentName : departmentName // ignore: cast_nullable_to_non_nullable
as String?,adLinked: null == adLinked ? _self.adLinked : adLinked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserRow].
extension UserRowPatterns on UserRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserRow value)  $default,){
final _that = this;
switch (_that) {
case _UserRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserRow value)?  $default,){
final _that = this;
switch (_that) {
case _UserRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'full_name')  String fullName,  String email, @JsonKey(name: 'phone_number')  String? phoneNumber, @JsonKey(name: 'is_active', fromJson: _boolFromInt)  bool isActive, @JsonKey(name: 'is_locked', fromJson: _boolFromInt)  bool isLocked, @JsonKey(name: 'mfa_enabled', fromJson: _boolFromInt)  bool mfaEnabled, @JsonKey(name: 'role_name')  String roleName, @JsonKey(name: 'department_id')  int? departmentId, @JsonKey(name: 'department_name')  String? departmentName, @JsonKey(name: 'ad_linked', fromJson: _boolFromInt)  bool adLinked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserRow() when $default != null:
return $default(_that.id,_that.fullName,_that.email,_that.phoneNumber,_that.isActive,_that.isLocked,_that.mfaEnabled,_that.roleName,_that.departmentId,_that.departmentName,_that.adLinked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'full_name')  String fullName,  String email, @JsonKey(name: 'phone_number')  String? phoneNumber, @JsonKey(name: 'is_active', fromJson: _boolFromInt)  bool isActive, @JsonKey(name: 'is_locked', fromJson: _boolFromInt)  bool isLocked, @JsonKey(name: 'mfa_enabled', fromJson: _boolFromInt)  bool mfaEnabled, @JsonKey(name: 'role_name')  String roleName, @JsonKey(name: 'department_id')  int? departmentId, @JsonKey(name: 'department_name')  String? departmentName, @JsonKey(name: 'ad_linked', fromJson: _boolFromInt)  bool adLinked)  $default,) {final _that = this;
switch (_that) {
case _UserRow():
return $default(_that.id,_that.fullName,_that.email,_that.phoneNumber,_that.isActive,_that.isLocked,_that.mfaEnabled,_that.roleName,_that.departmentId,_that.departmentName,_that.adLinked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'full_name')  String fullName,  String email, @JsonKey(name: 'phone_number')  String? phoneNumber, @JsonKey(name: 'is_active', fromJson: _boolFromInt)  bool isActive, @JsonKey(name: 'is_locked', fromJson: _boolFromInt)  bool isLocked, @JsonKey(name: 'mfa_enabled', fromJson: _boolFromInt)  bool mfaEnabled, @JsonKey(name: 'role_name')  String roleName, @JsonKey(name: 'department_id')  int? departmentId, @JsonKey(name: 'department_name')  String? departmentName, @JsonKey(name: 'ad_linked', fromJson: _boolFromInt)  bool adLinked)?  $default,) {final _that = this;
switch (_that) {
case _UserRow() when $default != null:
return $default(_that.id,_that.fullName,_that.email,_that.phoneNumber,_that.isActive,_that.isLocked,_that.mfaEnabled,_that.roleName,_that.departmentId,_that.departmentName,_that.adLinked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserRow implements UserRow {
  const _UserRow({required this.id, @JsonKey(name: 'full_name') required this.fullName, required this.email, @JsonKey(name: 'phone_number') this.phoneNumber, @JsonKey(name: 'is_active', fromJson: _boolFromInt) required this.isActive, @JsonKey(name: 'is_locked', fromJson: _boolFromInt) required this.isLocked, @JsonKey(name: 'mfa_enabled', fromJson: _boolFromInt) required this.mfaEnabled, @JsonKey(name: 'role_name') required this.roleName, @JsonKey(name: 'department_id') this.departmentId, @JsonKey(name: 'department_name') this.departmentName, @JsonKey(name: 'ad_linked', fromJson: _boolFromInt) this.adLinked = false});
  factory _UserRow.fromJson(Map<String, dynamic> json) => _$UserRowFromJson(json);

@override final  int id;
@override@JsonKey(name: 'full_name') final  String fullName;
@override final  String email;
@override@JsonKey(name: 'phone_number') final  String? phoneNumber;
@override@JsonKey(name: 'is_active', fromJson: _boolFromInt) final  bool isActive;
@override@JsonKey(name: 'is_locked', fromJson: _boolFromInt) final  bool isLocked;
@override@JsonKey(name: 'mfa_enabled', fromJson: _boolFromInt) final  bool mfaEnabled;
@override@JsonKey(name: 'role_name') final  String roleName;
@override@JsonKey(name: 'department_id') final  int? departmentId;
@override@JsonKey(name: 'department_name') final  String? departmentName;
@override@JsonKey(name: 'ad_linked', fromJson: _boolFromInt) final  bool adLinked;

/// Create a copy of UserRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserRowCopyWith<_UserRow> get copyWith => __$UserRowCopyWithImpl<_UserRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserRow&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.mfaEnabled, mfaEnabled) || other.mfaEnabled == mfaEnabled)&&(identical(other.roleName, roleName) || other.roleName == roleName)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.departmentName, departmentName) || other.departmentName == departmentName)&&(identical(other.adLinked, adLinked) || other.adLinked == adLinked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,email,phoneNumber,isActive,isLocked,mfaEnabled,roleName,departmentId,departmentName,adLinked);

@override
String toString() {
  return 'UserRow(id: $id, fullName: $fullName, email: $email, phoneNumber: $phoneNumber, isActive: $isActive, isLocked: $isLocked, mfaEnabled: $mfaEnabled, roleName: $roleName, departmentId: $departmentId, departmentName: $departmentName, adLinked: $adLinked)';
}


}

/// @nodoc
abstract mixin class _$UserRowCopyWith<$Res> implements $UserRowCopyWith<$Res> {
  factory _$UserRowCopyWith(_UserRow value, $Res Function(_UserRow) _then) = __$UserRowCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'full_name') String fullName, String email,@JsonKey(name: 'phone_number') String? phoneNumber,@JsonKey(name: 'is_active', fromJson: _boolFromInt) bool isActive,@JsonKey(name: 'is_locked', fromJson: _boolFromInt) bool isLocked,@JsonKey(name: 'mfa_enabled', fromJson: _boolFromInt) bool mfaEnabled,@JsonKey(name: 'role_name') String roleName,@JsonKey(name: 'department_id') int? departmentId,@JsonKey(name: 'department_name') String? departmentName,@JsonKey(name: 'ad_linked', fromJson: _boolFromInt) bool adLinked
});




}
/// @nodoc
class __$UserRowCopyWithImpl<$Res>
    implements _$UserRowCopyWith<$Res> {
  __$UserRowCopyWithImpl(this._self, this._then);

  final _UserRow _self;
  final $Res Function(_UserRow) _then;

/// Create a copy of UserRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? email = null,Object? phoneNumber = freezed,Object? isActive = null,Object? isLocked = null,Object? mfaEnabled = null,Object? roleName = null,Object? departmentId = freezed,Object? departmentName = freezed,Object? adLinked = null,}) {
  return _then(_UserRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,mfaEnabled: null == mfaEnabled ? _self.mfaEnabled : mfaEnabled // ignore: cast_nullable_to_non_nullable
as bool,roleName: null == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as String,departmentId: freezed == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as int?,departmentName: freezed == departmentName ? _self.departmentName : departmentName // ignore: cast_nullable_to_non_nullable
as String?,adLinked: null == adLinked ? _self.adLinked : adLinked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
