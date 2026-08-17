// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'department_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DepartmentRow {

 int get id; String get name; String? get description;@JsonKey(name: 'is_active', fromJson: _boolFromInt) bool get isActive;
/// Create a copy of DepartmentRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DepartmentRowCopyWith<DepartmentRow> get copyWith => _$DepartmentRowCopyWithImpl<DepartmentRow>(this as DepartmentRow, _$identity);

  /// Serializes this DepartmentRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DepartmentRow&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,isActive);

@override
String toString() {
  return 'DepartmentRow(id: $id, name: $name, description: $description, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $DepartmentRowCopyWith<$Res>  {
  factory $DepartmentRowCopyWith(DepartmentRow value, $Res Function(DepartmentRow) _then) = _$DepartmentRowCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? description,@JsonKey(name: 'is_active', fromJson: _boolFromInt) bool isActive
});




}
/// @nodoc
class _$DepartmentRowCopyWithImpl<$Res>
    implements $DepartmentRowCopyWith<$Res> {
  _$DepartmentRowCopyWithImpl(this._self, this._then);

  final DepartmentRow _self;
  final $Res Function(DepartmentRow) _then;

/// Create a copy of DepartmentRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DepartmentRow].
extension DepartmentRowPatterns on DepartmentRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DepartmentRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DepartmentRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DepartmentRow value)  $default,){
final _that = this;
switch (_that) {
case _DepartmentRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DepartmentRow value)?  $default,){
final _that = this;
switch (_that) {
case _DepartmentRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? description, @JsonKey(name: 'is_active', fromJson: _boolFromInt)  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DepartmentRow() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? description, @JsonKey(name: 'is_active', fromJson: _boolFromInt)  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _DepartmentRow():
return $default(_that.id,_that.name,_that.description,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? description, @JsonKey(name: 'is_active', fromJson: _boolFromInt)  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _DepartmentRow() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DepartmentRow implements DepartmentRow {
  const _DepartmentRow({required this.id, required this.name, this.description, @JsonKey(name: 'is_active', fromJson: _boolFromInt) required this.isActive});
  factory _DepartmentRow.fromJson(Map<String, dynamic> json) => _$DepartmentRowFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? description;
@override@JsonKey(name: 'is_active', fromJson: _boolFromInt) final  bool isActive;

/// Create a copy of DepartmentRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DepartmentRowCopyWith<_DepartmentRow> get copyWith => __$DepartmentRowCopyWithImpl<_DepartmentRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DepartmentRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DepartmentRow&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,isActive);

@override
String toString() {
  return 'DepartmentRow(id: $id, name: $name, description: $description, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$DepartmentRowCopyWith<$Res> implements $DepartmentRowCopyWith<$Res> {
  factory _$DepartmentRowCopyWith(_DepartmentRow value, $Res Function(_DepartmentRow) _then) = __$DepartmentRowCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? description,@JsonKey(name: 'is_active', fromJson: _boolFromInt) bool isActive
});




}
/// @nodoc
class __$DepartmentRowCopyWithImpl<$Res>
    implements _$DepartmentRowCopyWith<$Res> {
  __$DepartmentRowCopyWithImpl(this._self, this._then);

  final _DepartmentRow _self;
  final $Res Function(_DepartmentRow) _then;

/// Create a copy of DepartmentRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? isActive = null,}) {
  return _then(_DepartmentRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
