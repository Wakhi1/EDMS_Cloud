// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'share_link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShareLink {

 int get id; String get token;@JsonKey(name: 'expires_at') String get expiresAt;@JsonKey(name: 'revoked_at') String? get revokedAt;@JsonKey(name: 'access_count') int get accessCount;@JsonKey(name: 'last_accessed_at') String? get lastAccessedAt;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'document_id') int get documentId;@JsonKey(name: 'record_no') String get recordNo; String get title;@JsonKey(name: 'created_by_name') String? get createdByName;
/// Create a copy of ShareLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShareLinkCopyWith<ShareLink> get copyWith => _$ShareLinkCopyWithImpl<ShareLink>(this as ShareLink, _$identity);

  /// Serializes this ShareLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShareLink&&(identical(other.id, id) || other.id == id)&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.revokedAt, revokedAt) || other.revokedAt == revokedAt)&&(identical(other.accessCount, accessCount) || other.accessCount == accessCount)&&(identical(other.lastAccessedAt, lastAccessedAt) || other.lastAccessedAt == lastAccessedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.recordNo, recordNo) || other.recordNo == recordNo)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,token,expiresAt,revokedAt,accessCount,lastAccessedAt,createdAt,documentId,recordNo,title,createdByName);

@override
String toString() {
  return 'ShareLink(id: $id, token: $token, expiresAt: $expiresAt, revokedAt: $revokedAt, accessCount: $accessCount, lastAccessedAt: $lastAccessedAt, createdAt: $createdAt, documentId: $documentId, recordNo: $recordNo, title: $title, createdByName: $createdByName)';
}


}

/// @nodoc
abstract mixin class $ShareLinkCopyWith<$Res>  {
  factory $ShareLinkCopyWith(ShareLink value, $Res Function(ShareLink) _then) = _$ShareLinkCopyWithImpl;
@useResult
$Res call({
 int id, String token,@JsonKey(name: 'expires_at') String expiresAt,@JsonKey(name: 'revoked_at') String? revokedAt,@JsonKey(name: 'access_count') int accessCount,@JsonKey(name: 'last_accessed_at') String? lastAccessedAt,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'document_id') int documentId,@JsonKey(name: 'record_no') String recordNo, String title,@JsonKey(name: 'created_by_name') String? createdByName
});




}
/// @nodoc
class _$ShareLinkCopyWithImpl<$Res>
    implements $ShareLinkCopyWith<$Res> {
  _$ShareLinkCopyWithImpl(this._self, this._then);

  final ShareLink _self;
  final $Res Function(ShareLink) _then;

/// Create a copy of ShareLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? token = null,Object? expiresAt = null,Object? revokedAt = freezed,Object? accessCount = null,Object? lastAccessedAt = freezed,Object? createdAt = null,Object? documentId = null,Object? recordNo = null,Object? title = null,Object? createdByName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,revokedAt: freezed == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as String?,accessCount: null == accessCount ? _self.accessCount : accessCount // ignore: cast_nullable_to_non_nullable
as int,lastAccessedAt: freezed == lastAccessedAt ? _self.lastAccessedAt : lastAccessedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as int,recordNo: null == recordNo ? _self.recordNo : recordNo // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShareLink].
extension ShareLinkPatterns on ShareLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShareLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShareLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShareLink value)  $default,){
final _that = this;
switch (_that) {
case _ShareLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShareLink value)?  $default,){
final _that = this;
switch (_that) {
case _ShareLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String token, @JsonKey(name: 'expires_at')  String expiresAt, @JsonKey(name: 'revoked_at')  String? revokedAt, @JsonKey(name: 'access_count')  int accessCount, @JsonKey(name: 'last_accessed_at')  String? lastAccessedAt, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'document_id')  int documentId, @JsonKey(name: 'record_no')  String recordNo,  String title, @JsonKey(name: 'created_by_name')  String? createdByName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShareLink() when $default != null:
return $default(_that.id,_that.token,_that.expiresAt,_that.revokedAt,_that.accessCount,_that.lastAccessedAt,_that.createdAt,_that.documentId,_that.recordNo,_that.title,_that.createdByName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String token, @JsonKey(name: 'expires_at')  String expiresAt, @JsonKey(name: 'revoked_at')  String? revokedAt, @JsonKey(name: 'access_count')  int accessCount, @JsonKey(name: 'last_accessed_at')  String? lastAccessedAt, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'document_id')  int documentId, @JsonKey(name: 'record_no')  String recordNo,  String title, @JsonKey(name: 'created_by_name')  String? createdByName)  $default,) {final _that = this;
switch (_that) {
case _ShareLink():
return $default(_that.id,_that.token,_that.expiresAt,_that.revokedAt,_that.accessCount,_that.lastAccessedAt,_that.createdAt,_that.documentId,_that.recordNo,_that.title,_that.createdByName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String token, @JsonKey(name: 'expires_at')  String expiresAt, @JsonKey(name: 'revoked_at')  String? revokedAt, @JsonKey(name: 'access_count')  int accessCount, @JsonKey(name: 'last_accessed_at')  String? lastAccessedAt, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'document_id')  int documentId, @JsonKey(name: 'record_no')  String recordNo,  String title, @JsonKey(name: 'created_by_name')  String? createdByName)?  $default,) {final _that = this;
switch (_that) {
case _ShareLink() when $default != null:
return $default(_that.id,_that.token,_that.expiresAt,_that.revokedAt,_that.accessCount,_that.lastAccessedAt,_that.createdAt,_that.documentId,_that.recordNo,_that.title,_that.createdByName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShareLink implements ShareLink {
  const _ShareLink({required this.id, required this.token, @JsonKey(name: 'expires_at') required this.expiresAt, @JsonKey(name: 'revoked_at') this.revokedAt, @JsonKey(name: 'access_count') required this.accessCount, @JsonKey(name: 'last_accessed_at') this.lastAccessedAt, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'document_id') required this.documentId, @JsonKey(name: 'record_no') required this.recordNo, required this.title, @JsonKey(name: 'created_by_name') this.createdByName});
  factory _ShareLink.fromJson(Map<String, dynamic> json) => _$ShareLinkFromJson(json);

@override final  int id;
@override final  String token;
@override@JsonKey(name: 'expires_at') final  String expiresAt;
@override@JsonKey(name: 'revoked_at') final  String? revokedAt;
@override@JsonKey(name: 'access_count') final  int accessCount;
@override@JsonKey(name: 'last_accessed_at') final  String? lastAccessedAt;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'document_id') final  int documentId;
@override@JsonKey(name: 'record_no') final  String recordNo;
@override final  String title;
@override@JsonKey(name: 'created_by_name') final  String? createdByName;

/// Create a copy of ShareLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShareLinkCopyWith<_ShareLink> get copyWith => __$ShareLinkCopyWithImpl<_ShareLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShareLinkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShareLink&&(identical(other.id, id) || other.id == id)&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.revokedAt, revokedAt) || other.revokedAt == revokedAt)&&(identical(other.accessCount, accessCount) || other.accessCount == accessCount)&&(identical(other.lastAccessedAt, lastAccessedAt) || other.lastAccessedAt == lastAccessedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.recordNo, recordNo) || other.recordNo == recordNo)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,token,expiresAt,revokedAt,accessCount,lastAccessedAt,createdAt,documentId,recordNo,title,createdByName);

@override
String toString() {
  return 'ShareLink(id: $id, token: $token, expiresAt: $expiresAt, revokedAt: $revokedAt, accessCount: $accessCount, lastAccessedAt: $lastAccessedAt, createdAt: $createdAt, documentId: $documentId, recordNo: $recordNo, title: $title, createdByName: $createdByName)';
}


}

/// @nodoc
abstract mixin class _$ShareLinkCopyWith<$Res> implements $ShareLinkCopyWith<$Res> {
  factory _$ShareLinkCopyWith(_ShareLink value, $Res Function(_ShareLink) _then) = __$ShareLinkCopyWithImpl;
@override @useResult
$Res call({
 int id, String token,@JsonKey(name: 'expires_at') String expiresAt,@JsonKey(name: 'revoked_at') String? revokedAt,@JsonKey(name: 'access_count') int accessCount,@JsonKey(name: 'last_accessed_at') String? lastAccessedAt,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'document_id') int documentId,@JsonKey(name: 'record_no') String recordNo, String title,@JsonKey(name: 'created_by_name') String? createdByName
});




}
/// @nodoc
class __$ShareLinkCopyWithImpl<$Res>
    implements _$ShareLinkCopyWith<$Res> {
  __$ShareLinkCopyWithImpl(this._self, this._then);

  final _ShareLink _self;
  final $Res Function(_ShareLink) _then;

/// Create a copy of ShareLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? token = null,Object? expiresAt = null,Object? revokedAt = freezed,Object? accessCount = null,Object? lastAccessedAt = freezed,Object? createdAt = null,Object? documentId = null,Object? recordNo = null,Object? title = null,Object? createdByName = freezed,}) {
  return _then(_ShareLink(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,revokedAt: freezed == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as String?,accessCount: null == accessCount ? _self.accessCount : accessCount // ignore: cast_nullable_to_non_nullable
as int,lastAccessedAt: freezed == lastAccessedAt ? _self.lastAccessedAt : lastAccessedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as int,recordNo: null == recordNo ? _self.recordNo : recordNo // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
