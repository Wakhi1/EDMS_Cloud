// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FolderRow {

 int get id;@JsonKey(name: 'parent_id') int? get parentId; String get name; String get path;@JsonKey(name: 'department_id') int? get departmentId;@JsonKey(name: 'retention_class_id') int? get retentionClassId;@JsonKey(name: 'retention_class_name') String? get retentionClassName;
/// Create a copy of FolderRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderRowCopyWith<FolderRow> get copyWith => _$FolderRowCopyWithImpl<FolderRow>(this as FolderRow, _$identity);

  /// Serializes this FolderRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderRow&&(identical(other.id, id) || other.id == id)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.retentionClassId, retentionClassId) || other.retentionClassId == retentionClassId)&&(identical(other.retentionClassName, retentionClassName) || other.retentionClassName == retentionClassName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,parentId,name,path,departmentId,retentionClassId,retentionClassName);

@override
String toString() {
  return 'FolderRow(id: $id, parentId: $parentId, name: $name, path: $path, departmentId: $departmentId, retentionClassId: $retentionClassId, retentionClassName: $retentionClassName)';
}


}

/// @nodoc
abstract mixin class $FolderRowCopyWith<$Res>  {
  factory $FolderRowCopyWith(FolderRow value, $Res Function(FolderRow) _then) = _$FolderRowCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'parent_id') int? parentId, String name, String path,@JsonKey(name: 'department_id') int? departmentId,@JsonKey(name: 'retention_class_id') int? retentionClassId,@JsonKey(name: 'retention_class_name') String? retentionClassName
});




}
/// @nodoc
class _$FolderRowCopyWithImpl<$Res>
    implements $FolderRowCopyWith<$Res> {
  _$FolderRowCopyWithImpl(this._self, this._then);

  final FolderRow _self;
  final $Res Function(FolderRow) _then;

/// Create a copy of FolderRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? parentId = freezed,Object? name = null,Object? path = null,Object? departmentId = freezed,Object? retentionClassId = freezed,Object? retentionClassName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,departmentId: freezed == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as int?,retentionClassId: freezed == retentionClassId ? _self.retentionClassId : retentionClassId // ignore: cast_nullable_to_non_nullable
as int?,retentionClassName: freezed == retentionClassName ? _self.retentionClassName : retentionClassName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FolderRow].
extension FolderRowPatterns on FolderRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FolderRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FolderRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FolderRow value)  $default,){
final _that = this;
switch (_that) {
case _FolderRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FolderRow value)?  $default,){
final _that = this;
switch (_that) {
case _FolderRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'parent_id')  int? parentId,  String name,  String path, @JsonKey(name: 'department_id')  int? departmentId, @JsonKey(name: 'retention_class_id')  int? retentionClassId, @JsonKey(name: 'retention_class_name')  String? retentionClassName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FolderRow() when $default != null:
return $default(_that.id,_that.parentId,_that.name,_that.path,_that.departmentId,_that.retentionClassId,_that.retentionClassName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'parent_id')  int? parentId,  String name,  String path, @JsonKey(name: 'department_id')  int? departmentId, @JsonKey(name: 'retention_class_id')  int? retentionClassId, @JsonKey(name: 'retention_class_name')  String? retentionClassName)  $default,) {final _that = this;
switch (_that) {
case _FolderRow():
return $default(_that.id,_that.parentId,_that.name,_that.path,_that.departmentId,_that.retentionClassId,_that.retentionClassName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'parent_id')  int? parentId,  String name,  String path, @JsonKey(name: 'department_id')  int? departmentId, @JsonKey(name: 'retention_class_id')  int? retentionClassId, @JsonKey(name: 'retention_class_name')  String? retentionClassName)?  $default,) {final _that = this;
switch (_that) {
case _FolderRow() when $default != null:
return $default(_that.id,_that.parentId,_that.name,_that.path,_that.departmentId,_that.retentionClassId,_that.retentionClassName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FolderRow implements FolderRow {
  const _FolderRow({required this.id, @JsonKey(name: 'parent_id') this.parentId, required this.name, required this.path, @JsonKey(name: 'department_id') this.departmentId, @JsonKey(name: 'retention_class_id') this.retentionClassId, @JsonKey(name: 'retention_class_name') this.retentionClassName});
  factory _FolderRow.fromJson(Map<String, dynamic> json) => _$FolderRowFromJson(json);

@override final  int id;
@override@JsonKey(name: 'parent_id') final  int? parentId;
@override final  String name;
@override final  String path;
@override@JsonKey(name: 'department_id') final  int? departmentId;
@override@JsonKey(name: 'retention_class_id') final  int? retentionClassId;
@override@JsonKey(name: 'retention_class_name') final  String? retentionClassName;

/// Create a copy of FolderRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FolderRowCopyWith<_FolderRow> get copyWith => __$FolderRowCopyWithImpl<_FolderRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FolderRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FolderRow&&(identical(other.id, id) || other.id == id)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.departmentId, departmentId) || other.departmentId == departmentId)&&(identical(other.retentionClassId, retentionClassId) || other.retentionClassId == retentionClassId)&&(identical(other.retentionClassName, retentionClassName) || other.retentionClassName == retentionClassName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,parentId,name,path,departmentId,retentionClassId,retentionClassName);

@override
String toString() {
  return 'FolderRow(id: $id, parentId: $parentId, name: $name, path: $path, departmentId: $departmentId, retentionClassId: $retentionClassId, retentionClassName: $retentionClassName)';
}


}

/// @nodoc
abstract mixin class _$FolderRowCopyWith<$Res> implements $FolderRowCopyWith<$Res> {
  factory _$FolderRowCopyWith(_FolderRow value, $Res Function(_FolderRow) _then) = __$FolderRowCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'parent_id') int? parentId, String name, String path,@JsonKey(name: 'department_id') int? departmentId,@JsonKey(name: 'retention_class_id') int? retentionClassId,@JsonKey(name: 'retention_class_name') String? retentionClassName
});




}
/// @nodoc
class __$FolderRowCopyWithImpl<$Res>
    implements _$FolderRowCopyWith<$Res> {
  __$FolderRowCopyWithImpl(this._self, this._then);

  final _FolderRow _self;
  final $Res Function(_FolderRow) _then;

/// Create a copy of FolderRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? parentId = freezed,Object? name = null,Object? path = null,Object? departmentId = freezed,Object? retentionClassId = freezed,Object? retentionClassName = freezed,}) {
  return _then(_FolderRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,departmentId: freezed == departmentId ? _self.departmentId : departmentId // ignore: cast_nullable_to_non_nullable
as int?,retentionClassId: freezed == retentionClassId ? _self.retentionClassId : retentionClassId // ignore: cast_nullable_to_non_nullable
as int?,retentionClassName: freezed == retentionClassName ? _self.retentionClassName : retentionClassName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
