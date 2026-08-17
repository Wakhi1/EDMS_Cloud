// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_type_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DocumentTypeRow {

 int get id; String get name; String get code;
/// Create a copy of DocumentTypeRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentTypeRowCopyWith<DocumentTypeRow> get copyWith => _$DocumentTypeRowCopyWithImpl<DocumentTypeRow>(this as DocumentTypeRow, _$identity);

  /// Serializes this DocumentTypeRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentTypeRow&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,code);

@override
String toString() {
  return 'DocumentTypeRow(id: $id, name: $name, code: $code)';
}


}

/// @nodoc
abstract mixin class $DocumentTypeRowCopyWith<$Res>  {
  factory $DocumentTypeRowCopyWith(DocumentTypeRow value, $Res Function(DocumentTypeRow) _then) = _$DocumentTypeRowCopyWithImpl;
@useResult
$Res call({
 int id, String name, String code
});




}
/// @nodoc
class _$DocumentTypeRowCopyWithImpl<$Res>
    implements $DocumentTypeRowCopyWith<$Res> {
  _$DocumentTypeRowCopyWithImpl(this._self, this._then);

  final DocumentTypeRow _self;
  final $Res Function(DocumentTypeRow) _then;

/// Create a copy of DocumentTypeRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? code = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentTypeRow].
extension DocumentTypeRowPatterns on DocumentTypeRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentTypeRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentTypeRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentTypeRow value)  $default,){
final _that = this;
switch (_that) {
case _DocumentTypeRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentTypeRow value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentTypeRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentTypeRow() when $default != null:
return $default(_that.id,_that.name,_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String code)  $default,) {final _that = this;
switch (_that) {
case _DocumentTypeRow():
return $default(_that.id,_that.name,_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String code)?  $default,) {final _that = this;
switch (_that) {
case _DocumentTypeRow() when $default != null:
return $default(_that.id,_that.name,_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentTypeRow implements DocumentTypeRow {
  const _DocumentTypeRow({required this.id, required this.name, required this.code});
  factory _DocumentTypeRow.fromJson(Map<String, dynamic> json) => _$DocumentTypeRowFromJson(json);

@override final  int id;
@override final  String name;
@override final  String code;

/// Create a copy of DocumentTypeRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentTypeRowCopyWith<_DocumentTypeRow> get copyWith => __$DocumentTypeRowCopyWithImpl<_DocumentTypeRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentTypeRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentTypeRow&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,code);

@override
String toString() {
  return 'DocumentTypeRow(id: $id, name: $name, code: $code)';
}


}

/// @nodoc
abstract mixin class _$DocumentTypeRowCopyWith<$Res> implements $DocumentTypeRowCopyWith<$Res> {
  factory _$DocumentTypeRowCopyWith(_DocumentTypeRow value, $Res Function(_DocumentTypeRow) _then) = __$DocumentTypeRowCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String code
});




}
/// @nodoc
class __$DocumentTypeRowCopyWithImpl<$Res>
    implements _$DocumentTypeRowCopyWith<$Res> {
  __$DocumentTypeRowCopyWithImpl(this._self, this._then);

  final _DocumentTypeRow _self;
  final $Res Function(_DocumentTypeRow) _then;

/// Create a copy of DocumentTypeRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? code = null,}) {
  return _then(_DocumentTypeRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
