// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audit_log_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuditLogRow {

 int get id;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'user_name') String? get userName; String get action;@JsonKey(name: 'record_type') String? get recordType;@JsonKey(name: 'record_id') String? get recordId; String? get detail;@JsonKey(name: 'ip_address') String? get ipAddress;
/// Create a copy of AuditLogRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditLogRowCopyWith<AuditLogRow> get copyWith => _$AuditLogRowCopyWithImpl<AuditLogRow>(this as AuditLogRow, _$identity);

  /// Serializes this AuditLogRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditLogRow&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.action, action) || other.action == action)&&(identical(other.recordType, recordType) || other.recordType == recordType)&&(identical(other.recordId, recordId) || other.recordId == recordId)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,userName,action,recordType,recordId,detail,ipAddress);

@override
String toString() {
  return 'AuditLogRow(id: $id, createdAt: $createdAt, userName: $userName, action: $action, recordType: $recordType, recordId: $recordId, detail: $detail, ipAddress: $ipAddress)';
}


}

/// @nodoc
abstract mixin class $AuditLogRowCopyWith<$Res>  {
  factory $AuditLogRowCopyWith(AuditLogRow value, $Res Function(AuditLogRow) _then) = _$AuditLogRowCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'user_name') String? userName, String action,@JsonKey(name: 'record_type') String? recordType,@JsonKey(name: 'record_id') String? recordId, String? detail,@JsonKey(name: 'ip_address') String? ipAddress
});




}
/// @nodoc
class _$AuditLogRowCopyWithImpl<$Res>
    implements $AuditLogRowCopyWith<$Res> {
  _$AuditLogRowCopyWithImpl(this._self, this._then);

  final AuditLogRow _self;
  final $Res Function(AuditLogRow) _then;

/// Create a copy of AuditLogRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? createdAt = null,Object? userName = freezed,Object? action = null,Object? recordType = freezed,Object? recordId = freezed,Object? detail = freezed,Object? ipAddress = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,recordType: freezed == recordType ? _self.recordType : recordType // ignore: cast_nullable_to_non_nullable
as String?,recordId: freezed == recordId ? _self.recordId : recordId // ignore: cast_nullable_to_non_nullable
as String?,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditLogRow].
extension AuditLogRowPatterns on AuditLogRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditLogRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditLogRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditLogRow value)  $default,){
final _that = this;
switch (_that) {
case _AuditLogRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditLogRow value)?  $default,){
final _that = this;
switch (_that) {
case _AuditLogRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'user_name')  String? userName,  String action, @JsonKey(name: 'record_type')  String? recordType, @JsonKey(name: 'record_id')  String? recordId,  String? detail, @JsonKey(name: 'ip_address')  String? ipAddress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditLogRow() when $default != null:
return $default(_that.id,_that.createdAt,_that.userName,_that.action,_that.recordType,_that.recordId,_that.detail,_that.ipAddress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'user_name')  String? userName,  String action, @JsonKey(name: 'record_type')  String? recordType, @JsonKey(name: 'record_id')  String? recordId,  String? detail, @JsonKey(name: 'ip_address')  String? ipAddress)  $default,) {final _that = this;
switch (_that) {
case _AuditLogRow():
return $default(_that.id,_that.createdAt,_that.userName,_that.action,_that.recordType,_that.recordId,_that.detail,_that.ipAddress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'user_name')  String? userName,  String action, @JsonKey(name: 'record_type')  String? recordType, @JsonKey(name: 'record_id')  String? recordId,  String? detail, @JsonKey(name: 'ip_address')  String? ipAddress)?  $default,) {final _that = this;
switch (_that) {
case _AuditLogRow() when $default != null:
return $default(_that.id,_that.createdAt,_that.userName,_that.action,_that.recordType,_that.recordId,_that.detail,_that.ipAddress);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuditLogRow implements AuditLogRow {
  const _AuditLogRow({required this.id, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'user_name') this.userName, required this.action, @JsonKey(name: 'record_type') this.recordType, @JsonKey(name: 'record_id') this.recordId, this.detail, @JsonKey(name: 'ip_address') this.ipAddress});
  factory _AuditLogRow.fromJson(Map<String, dynamic> json) => _$AuditLogRowFromJson(json);

@override final  int id;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'user_name') final  String? userName;
@override final  String action;
@override@JsonKey(name: 'record_type') final  String? recordType;
@override@JsonKey(name: 'record_id') final  String? recordId;
@override final  String? detail;
@override@JsonKey(name: 'ip_address') final  String? ipAddress;

/// Create a copy of AuditLogRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditLogRowCopyWith<_AuditLogRow> get copyWith => __$AuditLogRowCopyWithImpl<_AuditLogRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuditLogRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditLogRow&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.action, action) || other.action == action)&&(identical(other.recordType, recordType) || other.recordType == recordType)&&(identical(other.recordId, recordId) || other.recordId == recordId)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,userName,action,recordType,recordId,detail,ipAddress);

@override
String toString() {
  return 'AuditLogRow(id: $id, createdAt: $createdAt, userName: $userName, action: $action, recordType: $recordType, recordId: $recordId, detail: $detail, ipAddress: $ipAddress)';
}


}

/// @nodoc
abstract mixin class _$AuditLogRowCopyWith<$Res> implements $AuditLogRowCopyWith<$Res> {
  factory _$AuditLogRowCopyWith(_AuditLogRow value, $Res Function(_AuditLogRow) _then) = __$AuditLogRowCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'user_name') String? userName, String action,@JsonKey(name: 'record_type') String? recordType,@JsonKey(name: 'record_id') String? recordId, String? detail,@JsonKey(name: 'ip_address') String? ipAddress
});




}
/// @nodoc
class __$AuditLogRowCopyWithImpl<$Res>
    implements _$AuditLogRowCopyWith<$Res> {
  __$AuditLogRowCopyWithImpl(this._self, this._then);

  final _AuditLogRow _self;
  final $Res Function(_AuditLogRow) _then;

/// Create a copy of AuditLogRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? createdAt = null,Object? userName = freezed,Object? action = null,Object? recordType = freezed,Object? recordId = freezed,Object? detail = freezed,Object? ipAddress = freezed,}) {
  return _then(_AuditLogRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,recordType: freezed == recordType ? _self.recordType : recordType // ignore: cast_nullable_to_non_nullable
as String?,recordId: freezed == recordId ? _self.recordId : recordId // ignore: cast_nullable_to_non_nullable
as String?,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
