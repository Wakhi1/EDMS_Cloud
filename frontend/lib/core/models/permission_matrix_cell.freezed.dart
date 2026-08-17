// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'permission_matrix_cell.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PermissionMatrixCell {

@JsonKey(name: 'role_id') int get roleId; String get module;@JsonKey(name: 'can_view', fromJson: _boolFromInt) bool get canView;@JsonKey(name: 'can_edit', fromJson: _boolFromInt) bool get canEdit;@JsonKey(name: 'role_name') String? get roleName;
/// Create a copy of PermissionMatrixCell
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PermissionMatrixCellCopyWith<PermissionMatrixCell> get copyWith => _$PermissionMatrixCellCopyWithImpl<PermissionMatrixCell>(this as PermissionMatrixCell, _$identity);

  /// Serializes this PermissionMatrixCell to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PermissionMatrixCell&&(identical(other.roleId, roleId) || other.roleId == roleId)&&(identical(other.module, module) || other.module == module)&&(identical(other.canView, canView) || other.canView == canView)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.roleName, roleName) || other.roleName == roleName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roleId,module,canView,canEdit,roleName);

@override
String toString() {
  return 'PermissionMatrixCell(roleId: $roleId, module: $module, canView: $canView, canEdit: $canEdit, roleName: $roleName)';
}


}

/// @nodoc
abstract mixin class $PermissionMatrixCellCopyWith<$Res>  {
  factory $PermissionMatrixCellCopyWith(PermissionMatrixCell value, $Res Function(PermissionMatrixCell) _then) = _$PermissionMatrixCellCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'role_id') int roleId, String module,@JsonKey(name: 'can_view', fromJson: _boolFromInt) bool canView,@JsonKey(name: 'can_edit', fromJson: _boolFromInt) bool canEdit,@JsonKey(name: 'role_name') String? roleName
});




}
/// @nodoc
class _$PermissionMatrixCellCopyWithImpl<$Res>
    implements $PermissionMatrixCellCopyWith<$Res> {
  _$PermissionMatrixCellCopyWithImpl(this._self, this._then);

  final PermissionMatrixCell _self;
  final $Res Function(PermissionMatrixCell) _then;

/// Create a copy of PermissionMatrixCell
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roleId = null,Object? module = null,Object? canView = null,Object? canEdit = null,Object? roleName = freezed,}) {
  return _then(_self.copyWith(
roleId: null == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as int,module: null == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String,canView: null == canView ? _self.canView : canView // ignore: cast_nullable_to_non_nullable
as bool,canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,roleName: freezed == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PermissionMatrixCell].
extension PermissionMatrixCellPatterns on PermissionMatrixCell {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PermissionMatrixCell value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PermissionMatrixCell() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PermissionMatrixCell value)  $default,){
final _that = this;
switch (_that) {
case _PermissionMatrixCell():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PermissionMatrixCell value)?  $default,){
final _that = this;
switch (_that) {
case _PermissionMatrixCell() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'role_id')  int roleId,  String module, @JsonKey(name: 'can_view', fromJson: _boolFromInt)  bool canView, @JsonKey(name: 'can_edit', fromJson: _boolFromInt)  bool canEdit, @JsonKey(name: 'role_name')  String? roleName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PermissionMatrixCell() when $default != null:
return $default(_that.roleId,_that.module,_that.canView,_that.canEdit,_that.roleName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'role_id')  int roleId,  String module, @JsonKey(name: 'can_view', fromJson: _boolFromInt)  bool canView, @JsonKey(name: 'can_edit', fromJson: _boolFromInt)  bool canEdit, @JsonKey(name: 'role_name')  String? roleName)  $default,) {final _that = this;
switch (_that) {
case _PermissionMatrixCell():
return $default(_that.roleId,_that.module,_that.canView,_that.canEdit,_that.roleName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'role_id')  int roleId,  String module, @JsonKey(name: 'can_view', fromJson: _boolFromInt)  bool canView, @JsonKey(name: 'can_edit', fromJson: _boolFromInt)  bool canEdit, @JsonKey(name: 'role_name')  String? roleName)?  $default,) {final _that = this;
switch (_that) {
case _PermissionMatrixCell() when $default != null:
return $default(_that.roleId,_that.module,_that.canView,_that.canEdit,_that.roleName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PermissionMatrixCell implements PermissionMatrixCell {
  const _PermissionMatrixCell({@JsonKey(name: 'role_id') required this.roleId, required this.module, @JsonKey(name: 'can_view', fromJson: _boolFromInt) required this.canView, @JsonKey(name: 'can_edit', fromJson: _boolFromInt) required this.canEdit, @JsonKey(name: 'role_name') this.roleName});
  factory _PermissionMatrixCell.fromJson(Map<String, dynamic> json) => _$PermissionMatrixCellFromJson(json);

@override@JsonKey(name: 'role_id') final  int roleId;
@override final  String module;
@override@JsonKey(name: 'can_view', fromJson: _boolFromInt) final  bool canView;
@override@JsonKey(name: 'can_edit', fromJson: _boolFromInt) final  bool canEdit;
@override@JsonKey(name: 'role_name') final  String? roleName;

/// Create a copy of PermissionMatrixCell
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PermissionMatrixCellCopyWith<_PermissionMatrixCell> get copyWith => __$PermissionMatrixCellCopyWithImpl<_PermissionMatrixCell>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PermissionMatrixCellToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PermissionMatrixCell&&(identical(other.roleId, roleId) || other.roleId == roleId)&&(identical(other.module, module) || other.module == module)&&(identical(other.canView, canView) || other.canView == canView)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.roleName, roleName) || other.roleName == roleName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roleId,module,canView,canEdit,roleName);

@override
String toString() {
  return 'PermissionMatrixCell(roleId: $roleId, module: $module, canView: $canView, canEdit: $canEdit, roleName: $roleName)';
}


}

/// @nodoc
abstract mixin class _$PermissionMatrixCellCopyWith<$Res> implements $PermissionMatrixCellCopyWith<$Res> {
  factory _$PermissionMatrixCellCopyWith(_PermissionMatrixCell value, $Res Function(_PermissionMatrixCell) _then) = __$PermissionMatrixCellCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'role_id') int roleId, String module,@JsonKey(name: 'can_view', fromJson: _boolFromInt) bool canView,@JsonKey(name: 'can_edit', fromJson: _boolFromInt) bool canEdit,@JsonKey(name: 'role_name') String? roleName
});




}
/// @nodoc
class __$PermissionMatrixCellCopyWithImpl<$Res>
    implements _$PermissionMatrixCellCopyWith<$Res> {
  __$PermissionMatrixCellCopyWithImpl(this._self, this._then);

  final _PermissionMatrixCell _self;
  final $Res Function(_PermissionMatrixCell) _then;

/// Create a copy of PermissionMatrixCell
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roleId = null,Object? module = null,Object? canView = null,Object? canEdit = null,Object? roleName = freezed,}) {
  return _then(_PermissionMatrixCell(
roleId: null == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as int,module: null == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String,canView: null == canView ? _self.canView : canView // ignore: cast_nullable_to_non_nullable
as bool,canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,roleName: freezed == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
