// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'share_public_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SharePublicInfo {

@JsonKey(name: 'record_no') String get recordNo; String get title; String get classification;@JsonKey(name: 'expires_at') String get expiresAt;
/// Create a copy of SharePublicInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SharePublicInfoCopyWith<SharePublicInfo> get copyWith => _$SharePublicInfoCopyWithImpl<SharePublicInfo>(this as SharePublicInfo, _$identity);

  /// Serializes this SharePublicInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharePublicInfo&&(identical(other.recordNo, recordNo) || other.recordNo == recordNo)&&(identical(other.title, title) || other.title == title)&&(identical(other.classification, classification) || other.classification == classification)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,recordNo,title,classification,expiresAt);

@override
String toString() {
  return 'SharePublicInfo(recordNo: $recordNo, title: $title, classification: $classification, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $SharePublicInfoCopyWith<$Res>  {
  factory $SharePublicInfoCopyWith(SharePublicInfo value, $Res Function(SharePublicInfo) _then) = _$SharePublicInfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'record_no') String recordNo, String title, String classification,@JsonKey(name: 'expires_at') String expiresAt
});




}
/// @nodoc
class _$SharePublicInfoCopyWithImpl<$Res>
    implements $SharePublicInfoCopyWith<$Res> {
  _$SharePublicInfoCopyWithImpl(this._self, this._then);

  final SharePublicInfo _self;
  final $Res Function(SharePublicInfo) _then;

/// Create a copy of SharePublicInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? recordNo = null,Object? title = null,Object? classification = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
recordNo: null == recordNo ? _self.recordNo : recordNo // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,classification: null == classification ? _self.classification : classification // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SharePublicInfo].
extension SharePublicInfoPatterns on SharePublicInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SharePublicInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SharePublicInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SharePublicInfo value)  $default,){
final _that = this;
switch (_that) {
case _SharePublicInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SharePublicInfo value)?  $default,){
final _that = this;
switch (_that) {
case _SharePublicInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'record_no')  String recordNo,  String title,  String classification, @JsonKey(name: 'expires_at')  String expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SharePublicInfo() when $default != null:
return $default(_that.recordNo,_that.title,_that.classification,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'record_no')  String recordNo,  String title,  String classification, @JsonKey(name: 'expires_at')  String expiresAt)  $default,) {final _that = this;
switch (_that) {
case _SharePublicInfo():
return $default(_that.recordNo,_that.title,_that.classification,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'record_no')  String recordNo,  String title,  String classification, @JsonKey(name: 'expires_at')  String expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _SharePublicInfo() when $default != null:
return $default(_that.recordNo,_that.title,_that.classification,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SharePublicInfo implements SharePublicInfo {
  const _SharePublicInfo({@JsonKey(name: 'record_no') required this.recordNo, required this.title, required this.classification, @JsonKey(name: 'expires_at') required this.expiresAt});
  factory _SharePublicInfo.fromJson(Map<String, dynamic> json) => _$SharePublicInfoFromJson(json);

@override@JsonKey(name: 'record_no') final  String recordNo;
@override final  String title;
@override final  String classification;
@override@JsonKey(name: 'expires_at') final  String expiresAt;

/// Create a copy of SharePublicInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SharePublicInfoCopyWith<_SharePublicInfo> get copyWith => __$SharePublicInfoCopyWithImpl<_SharePublicInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SharePublicInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SharePublicInfo&&(identical(other.recordNo, recordNo) || other.recordNo == recordNo)&&(identical(other.title, title) || other.title == title)&&(identical(other.classification, classification) || other.classification == classification)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,recordNo,title,classification,expiresAt);

@override
String toString() {
  return 'SharePublicInfo(recordNo: $recordNo, title: $title, classification: $classification, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$SharePublicInfoCopyWith<$Res> implements $SharePublicInfoCopyWith<$Res> {
  factory _$SharePublicInfoCopyWith(_SharePublicInfo value, $Res Function(_SharePublicInfo) _then) = __$SharePublicInfoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'record_no') String recordNo, String title, String classification,@JsonKey(name: 'expires_at') String expiresAt
});




}
/// @nodoc
class __$SharePublicInfoCopyWithImpl<$Res>
    implements _$SharePublicInfoCopyWith<$Res> {
  __$SharePublicInfoCopyWithImpl(this._self, this._then);

  final _SharePublicInfo _self;
  final $Res Function(_SharePublicInfo) _then;

/// Create a copy of SharePublicInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? recordNo = null,Object? title = null,Object? classification = null,Object? expiresAt = null,}) {
  return _then(_SharePublicInfo(
recordNo: null == recordNo ? _self.recordNo : recordNo // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,classification: null == classification ? _self.classification : classification // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
