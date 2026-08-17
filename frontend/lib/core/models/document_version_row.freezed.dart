// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_version_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DocumentVersionRow {

 int get id;@JsonKey(name: 'version_no') int get versionNo;@JsonKey(name: 'file_name') String get fileName;@JsonKey(name: 'size_bytes') int? get sizeBytes;@JsonKey(name: 'is_current', fromJson: _boolFromInt) bool get isCurrent;@JsonKey(name: 'created_at') String? get createdAt;@JsonKey(name: 'created_by') String? get createdBy;
/// Create a copy of DocumentVersionRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentVersionRowCopyWith<DocumentVersionRow> get copyWith => _$DocumentVersionRowCopyWithImpl<DocumentVersionRow>(this as DocumentVersionRow, _$identity);

  /// Serializes this DocumentVersionRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentVersionRow&&(identical(other.id, id) || other.id == id)&&(identical(other.versionNo, versionNo) || other.versionNo == versionNo)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.isCurrent, isCurrent) || other.isCurrent == isCurrent)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,versionNo,fileName,sizeBytes,isCurrent,createdAt,createdBy);

@override
String toString() {
  return 'DocumentVersionRow(id: $id, versionNo: $versionNo, fileName: $fileName, sizeBytes: $sizeBytes, isCurrent: $isCurrent, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $DocumentVersionRowCopyWith<$Res>  {
  factory $DocumentVersionRowCopyWith(DocumentVersionRow value, $Res Function(DocumentVersionRow) _then) = _$DocumentVersionRowCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'version_no') int versionNo,@JsonKey(name: 'file_name') String fileName,@JsonKey(name: 'size_bytes') int? sizeBytes,@JsonKey(name: 'is_current', fromJson: _boolFromInt) bool isCurrent,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'created_by') String? createdBy
});




}
/// @nodoc
class _$DocumentVersionRowCopyWithImpl<$Res>
    implements $DocumentVersionRowCopyWith<$Res> {
  _$DocumentVersionRowCopyWithImpl(this._self, this._then);

  final DocumentVersionRow _self;
  final $Res Function(DocumentVersionRow) _then;

/// Create a copy of DocumentVersionRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? versionNo = null,Object? fileName = null,Object? sizeBytes = freezed,Object? isCurrent = null,Object? createdAt = freezed,Object? createdBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,versionNo: null == versionNo ? _self.versionNo : versionNo // ignore: cast_nullable_to_non_nullable
as int,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,isCurrent: null == isCurrent ? _self.isCurrent : isCurrent // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentVersionRow].
extension DocumentVersionRowPatterns on DocumentVersionRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentVersionRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentVersionRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentVersionRow value)  $default,){
final _that = this;
switch (_that) {
case _DocumentVersionRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentVersionRow value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentVersionRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'version_no')  int versionNo, @JsonKey(name: 'file_name')  String fileName, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'is_current', fromJson: _boolFromInt)  bool isCurrent, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'created_by')  String? createdBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentVersionRow() when $default != null:
return $default(_that.id,_that.versionNo,_that.fileName,_that.sizeBytes,_that.isCurrent,_that.createdAt,_that.createdBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'version_no')  int versionNo, @JsonKey(name: 'file_name')  String fileName, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'is_current', fromJson: _boolFromInt)  bool isCurrent, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'created_by')  String? createdBy)  $default,) {final _that = this;
switch (_that) {
case _DocumentVersionRow():
return $default(_that.id,_that.versionNo,_that.fileName,_that.sizeBytes,_that.isCurrent,_that.createdAt,_that.createdBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'version_no')  int versionNo, @JsonKey(name: 'file_name')  String fileName, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'is_current', fromJson: _boolFromInt)  bool isCurrent, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'created_by')  String? createdBy)?  $default,) {final _that = this;
switch (_that) {
case _DocumentVersionRow() when $default != null:
return $default(_that.id,_that.versionNo,_that.fileName,_that.sizeBytes,_that.isCurrent,_that.createdAt,_that.createdBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentVersionRow implements DocumentVersionRow {
  const _DocumentVersionRow({required this.id, @JsonKey(name: 'version_no') required this.versionNo, @JsonKey(name: 'file_name') required this.fileName, @JsonKey(name: 'size_bytes') this.sizeBytes, @JsonKey(name: 'is_current', fromJson: _boolFromInt) required this.isCurrent, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'created_by') this.createdBy});
  factory _DocumentVersionRow.fromJson(Map<String, dynamic> json) => _$DocumentVersionRowFromJson(json);

@override final  int id;
@override@JsonKey(name: 'version_no') final  int versionNo;
@override@JsonKey(name: 'file_name') final  String fileName;
@override@JsonKey(name: 'size_bytes') final  int? sizeBytes;
@override@JsonKey(name: 'is_current', fromJson: _boolFromInt) final  bool isCurrent;
@override@JsonKey(name: 'created_at') final  String? createdAt;
@override@JsonKey(name: 'created_by') final  String? createdBy;

/// Create a copy of DocumentVersionRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentVersionRowCopyWith<_DocumentVersionRow> get copyWith => __$DocumentVersionRowCopyWithImpl<_DocumentVersionRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentVersionRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentVersionRow&&(identical(other.id, id) || other.id == id)&&(identical(other.versionNo, versionNo) || other.versionNo == versionNo)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.isCurrent, isCurrent) || other.isCurrent == isCurrent)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,versionNo,fileName,sizeBytes,isCurrent,createdAt,createdBy);

@override
String toString() {
  return 'DocumentVersionRow(id: $id, versionNo: $versionNo, fileName: $fileName, sizeBytes: $sizeBytes, isCurrent: $isCurrent, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$DocumentVersionRowCopyWith<$Res> implements $DocumentVersionRowCopyWith<$Res> {
  factory _$DocumentVersionRowCopyWith(_DocumentVersionRow value, $Res Function(_DocumentVersionRow) _then) = __$DocumentVersionRowCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'version_no') int versionNo,@JsonKey(name: 'file_name') String fileName,@JsonKey(name: 'size_bytes') int? sizeBytes,@JsonKey(name: 'is_current', fromJson: _boolFromInt) bool isCurrent,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'created_by') String? createdBy
});




}
/// @nodoc
class __$DocumentVersionRowCopyWithImpl<$Res>
    implements _$DocumentVersionRowCopyWith<$Res> {
  __$DocumentVersionRowCopyWithImpl(this._self, this._then);

  final _DocumentVersionRow _self;
  final $Res Function(_DocumentVersionRow) _then;

/// Create a copy of DocumentVersionRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? versionNo = null,Object? fileName = null,Object? sizeBytes = freezed,Object? isCurrent = null,Object? createdAt = freezed,Object? createdBy = freezed,}) {
  return _then(_DocumentVersionRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,versionNo: null == versionNo ? _self.versionNo : versionNo // ignore: cast_nullable_to_non_nullable
as int,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,isCurrent: null == isCurrent ? _self.isCurrent : isCurrent // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
