// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ocr_preview_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OcrPreviewResult {

 String? get text; int? get confidence; int? get suggestedDocumentTypeId; String? get suggestedMemberNumber; DuplicateOfInfo? get duplicateOf;
/// Create a copy of OcrPreviewResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OcrPreviewResultCopyWith<OcrPreviewResult> get copyWith => _$OcrPreviewResultCopyWithImpl<OcrPreviewResult>(this as OcrPreviewResult, _$identity);

  /// Serializes this OcrPreviewResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OcrPreviewResult&&(identical(other.text, text) || other.text == text)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.suggestedDocumentTypeId, suggestedDocumentTypeId) || other.suggestedDocumentTypeId == suggestedDocumentTypeId)&&(identical(other.suggestedMemberNumber, suggestedMemberNumber) || other.suggestedMemberNumber == suggestedMemberNumber)&&(identical(other.duplicateOf, duplicateOf) || other.duplicateOf == duplicateOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,confidence,suggestedDocumentTypeId,suggestedMemberNumber,duplicateOf);

@override
String toString() {
  return 'OcrPreviewResult(text: $text, confidence: $confidence, suggestedDocumentTypeId: $suggestedDocumentTypeId, suggestedMemberNumber: $suggestedMemberNumber, duplicateOf: $duplicateOf)';
}


}

/// @nodoc
abstract mixin class $OcrPreviewResultCopyWith<$Res>  {
  factory $OcrPreviewResultCopyWith(OcrPreviewResult value, $Res Function(OcrPreviewResult) _then) = _$OcrPreviewResultCopyWithImpl;
@useResult
$Res call({
 String? text, int? confidence, int? suggestedDocumentTypeId, String? suggestedMemberNumber, DuplicateOfInfo? duplicateOf
});


$DuplicateOfInfoCopyWith<$Res>? get duplicateOf;

}
/// @nodoc
class _$OcrPreviewResultCopyWithImpl<$Res>
    implements $OcrPreviewResultCopyWith<$Res> {
  _$OcrPreviewResultCopyWithImpl(this._self, this._then);

  final OcrPreviewResult _self;
  final $Res Function(OcrPreviewResult) _then;

/// Create a copy of OcrPreviewResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = freezed,Object? confidence = freezed,Object? suggestedDocumentTypeId = freezed,Object? suggestedMemberNumber = freezed,Object? duplicateOf = freezed,}) {
  return _then(_self.copyWith(
text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as int?,suggestedDocumentTypeId: freezed == suggestedDocumentTypeId ? _self.suggestedDocumentTypeId : suggestedDocumentTypeId // ignore: cast_nullable_to_non_nullable
as int?,suggestedMemberNumber: freezed == suggestedMemberNumber ? _self.suggestedMemberNumber : suggestedMemberNumber // ignore: cast_nullable_to_non_nullable
as String?,duplicateOf: freezed == duplicateOf ? _self.duplicateOf : duplicateOf // ignore: cast_nullable_to_non_nullable
as DuplicateOfInfo?,
  ));
}
/// Create a copy of OcrPreviewResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuplicateOfInfoCopyWith<$Res>? get duplicateOf {
    if (_self.duplicateOf == null) {
    return null;
  }

  return $DuplicateOfInfoCopyWith<$Res>(_self.duplicateOf!, (value) {
    return _then(_self.copyWith(duplicateOf: value));
  });
}
}


/// Adds pattern-matching-related methods to [OcrPreviewResult].
extension OcrPreviewResultPatterns on OcrPreviewResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OcrPreviewResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OcrPreviewResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OcrPreviewResult value)  $default,){
final _that = this;
switch (_that) {
case _OcrPreviewResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OcrPreviewResult value)?  $default,){
final _that = this;
switch (_that) {
case _OcrPreviewResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? text,  int? confidence,  int? suggestedDocumentTypeId,  String? suggestedMemberNumber,  DuplicateOfInfo? duplicateOf)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OcrPreviewResult() when $default != null:
return $default(_that.text,_that.confidence,_that.suggestedDocumentTypeId,_that.suggestedMemberNumber,_that.duplicateOf);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? text,  int? confidence,  int? suggestedDocumentTypeId,  String? suggestedMemberNumber,  DuplicateOfInfo? duplicateOf)  $default,) {final _that = this;
switch (_that) {
case _OcrPreviewResult():
return $default(_that.text,_that.confidence,_that.suggestedDocumentTypeId,_that.suggestedMemberNumber,_that.duplicateOf);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? text,  int? confidence,  int? suggestedDocumentTypeId,  String? suggestedMemberNumber,  DuplicateOfInfo? duplicateOf)?  $default,) {final _that = this;
switch (_that) {
case _OcrPreviewResult() when $default != null:
return $default(_that.text,_that.confidence,_that.suggestedDocumentTypeId,_that.suggestedMemberNumber,_that.duplicateOf);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OcrPreviewResult implements OcrPreviewResult {
  const _OcrPreviewResult({this.text, this.confidence, this.suggestedDocumentTypeId, this.suggestedMemberNumber, this.duplicateOf});
  factory _OcrPreviewResult.fromJson(Map<String, dynamic> json) => _$OcrPreviewResultFromJson(json);

@override final  String? text;
@override final  int? confidence;
@override final  int? suggestedDocumentTypeId;
@override final  String? suggestedMemberNumber;
@override final  DuplicateOfInfo? duplicateOf;

/// Create a copy of OcrPreviewResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OcrPreviewResultCopyWith<_OcrPreviewResult> get copyWith => __$OcrPreviewResultCopyWithImpl<_OcrPreviewResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OcrPreviewResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OcrPreviewResult&&(identical(other.text, text) || other.text == text)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.suggestedDocumentTypeId, suggestedDocumentTypeId) || other.suggestedDocumentTypeId == suggestedDocumentTypeId)&&(identical(other.suggestedMemberNumber, suggestedMemberNumber) || other.suggestedMemberNumber == suggestedMemberNumber)&&(identical(other.duplicateOf, duplicateOf) || other.duplicateOf == duplicateOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,confidence,suggestedDocumentTypeId,suggestedMemberNumber,duplicateOf);

@override
String toString() {
  return 'OcrPreviewResult(text: $text, confidence: $confidence, suggestedDocumentTypeId: $suggestedDocumentTypeId, suggestedMemberNumber: $suggestedMemberNumber, duplicateOf: $duplicateOf)';
}


}

/// @nodoc
abstract mixin class _$OcrPreviewResultCopyWith<$Res> implements $OcrPreviewResultCopyWith<$Res> {
  factory _$OcrPreviewResultCopyWith(_OcrPreviewResult value, $Res Function(_OcrPreviewResult) _then) = __$OcrPreviewResultCopyWithImpl;
@override @useResult
$Res call({
 String? text, int? confidence, int? suggestedDocumentTypeId, String? suggestedMemberNumber, DuplicateOfInfo? duplicateOf
});


@override $DuplicateOfInfoCopyWith<$Res>? get duplicateOf;

}
/// @nodoc
class __$OcrPreviewResultCopyWithImpl<$Res>
    implements _$OcrPreviewResultCopyWith<$Res> {
  __$OcrPreviewResultCopyWithImpl(this._self, this._then);

  final _OcrPreviewResult _self;
  final $Res Function(_OcrPreviewResult) _then;

/// Create a copy of OcrPreviewResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = freezed,Object? confidence = freezed,Object? suggestedDocumentTypeId = freezed,Object? suggestedMemberNumber = freezed,Object? duplicateOf = freezed,}) {
  return _then(_OcrPreviewResult(
text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as int?,suggestedDocumentTypeId: freezed == suggestedDocumentTypeId ? _self.suggestedDocumentTypeId : suggestedDocumentTypeId // ignore: cast_nullable_to_non_nullable
as int?,suggestedMemberNumber: freezed == suggestedMemberNumber ? _self.suggestedMemberNumber : suggestedMemberNumber // ignore: cast_nullable_to_non_nullable
as String?,duplicateOf: freezed == duplicateOf ? _self.duplicateOf : duplicateOf // ignore: cast_nullable_to_non_nullable
as DuplicateOfInfo?,
  ));
}

/// Create a copy of OcrPreviewResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuplicateOfInfoCopyWith<$Res>? get duplicateOf {
    if (_self.duplicateOf == null) {
    return null;
  }

  return $DuplicateOfInfoCopyWith<$Res>(_self.duplicateOf!, (value) {
    return _then(_self.copyWith(duplicateOf: value));
  });
}
}


/// @nodoc
mixin _$DuplicateOfInfo {

 int get id; String get recordNo; String get title;
/// Create a copy of DuplicateOfInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuplicateOfInfoCopyWith<DuplicateOfInfo> get copyWith => _$DuplicateOfInfoCopyWithImpl<DuplicateOfInfo>(this as DuplicateOfInfo, _$identity);

  /// Serializes this DuplicateOfInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuplicateOfInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.recordNo, recordNo) || other.recordNo == recordNo)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,recordNo,title);

@override
String toString() {
  return 'DuplicateOfInfo(id: $id, recordNo: $recordNo, title: $title)';
}


}

/// @nodoc
abstract mixin class $DuplicateOfInfoCopyWith<$Res>  {
  factory $DuplicateOfInfoCopyWith(DuplicateOfInfo value, $Res Function(DuplicateOfInfo) _then) = _$DuplicateOfInfoCopyWithImpl;
@useResult
$Res call({
 int id, String recordNo, String title
});




}
/// @nodoc
class _$DuplicateOfInfoCopyWithImpl<$Res>
    implements $DuplicateOfInfoCopyWith<$Res> {
  _$DuplicateOfInfoCopyWithImpl(this._self, this._then);

  final DuplicateOfInfo _self;
  final $Res Function(DuplicateOfInfo) _then;

/// Create a copy of DuplicateOfInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? recordNo = null,Object? title = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,recordNo: null == recordNo ? _self.recordNo : recordNo // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DuplicateOfInfo].
extension DuplicateOfInfoPatterns on DuplicateOfInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuplicateOfInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuplicateOfInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuplicateOfInfo value)  $default,){
final _that = this;
switch (_that) {
case _DuplicateOfInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuplicateOfInfo value)?  $default,){
final _that = this;
switch (_that) {
case _DuplicateOfInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String recordNo,  String title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuplicateOfInfo() when $default != null:
return $default(_that.id,_that.recordNo,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String recordNo,  String title)  $default,) {final _that = this;
switch (_that) {
case _DuplicateOfInfo():
return $default(_that.id,_that.recordNo,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String recordNo,  String title)?  $default,) {final _that = this;
switch (_that) {
case _DuplicateOfInfo() when $default != null:
return $default(_that.id,_that.recordNo,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DuplicateOfInfo implements DuplicateOfInfo {
  const _DuplicateOfInfo({required this.id, required this.recordNo, required this.title});
  factory _DuplicateOfInfo.fromJson(Map<String, dynamic> json) => _$DuplicateOfInfoFromJson(json);

@override final  int id;
@override final  String recordNo;
@override final  String title;

/// Create a copy of DuplicateOfInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuplicateOfInfoCopyWith<_DuplicateOfInfo> get copyWith => __$DuplicateOfInfoCopyWithImpl<_DuplicateOfInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuplicateOfInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuplicateOfInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.recordNo, recordNo) || other.recordNo == recordNo)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,recordNo,title);

@override
String toString() {
  return 'DuplicateOfInfo(id: $id, recordNo: $recordNo, title: $title)';
}


}

/// @nodoc
abstract mixin class _$DuplicateOfInfoCopyWith<$Res> implements $DuplicateOfInfoCopyWith<$Res> {
  factory _$DuplicateOfInfoCopyWith(_DuplicateOfInfo value, $Res Function(_DuplicateOfInfo) _then) = __$DuplicateOfInfoCopyWithImpl;
@override @useResult
$Res call({
 int id, String recordNo, String title
});




}
/// @nodoc
class __$DuplicateOfInfoCopyWithImpl<$Res>
    implements _$DuplicateOfInfoCopyWith<$Res> {
  __$DuplicateOfInfoCopyWithImpl(this._self, this._then);

  final _DuplicateOfInfo _self;
  final $Res Function(_DuplicateOfInfo) _then;

/// Create a copy of DuplicateOfInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? recordNo = null,Object? title = null,}) {
  return _then(_DuplicateOfInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,recordNo: null == recordNo ? _self.recordNo : recordNo // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
