// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'access_request_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AccessRequestRow {

 int get id;@JsonKey(name: 'target_type') String get targetType;@JsonKey(name: 'target_id') int get targetId;@JsonKey(name: 'requested_level') String get requestedLevel; String? get reason;@JsonKey(name: 'requester_id') int get requesterId;@JsonKey(name: 'requester_name') String? get requesterName; String get status;@JsonKey(name: 'decided_by') int? get decidedBy;@JsonKey(name: 'decided_by_name') String? get decidedByName;@JsonKey(name: 'decided_at') String? get decidedAt;@JsonKey(name: 'decision_note') String? get decisionNote;@JsonKey(name: 'created_at') String? get createdAt;
/// Create a copy of AccessRequestRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccessRequestRowCopyWith<AccessRequestRow> get copyWith => _$AccessRequestRowCopyWithImpl<AccessRequestRow>(this as AccessRequestRow, _$identity);

  /// Serializes this AccessRequestRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccessRequestRow&&(identical(other.id, id) || other.id == id)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.requestedLevel, requestedLevel) || other.requestedLevel == requestedLevel)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.requesterId, requesterId) || other.requesterId == requesterId)&&(identical(other.requesterName, requesterName) || other.requesterName == requesterName)&&(identical(other.status, status) || other.status == status)&&(identical(other.decidedBy, decidedBy) || other.decidedBy == decidedBy)&&(identical(other.decidedByName, decidedByName) || other.decidedByName == decidedByName)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.decisionNote, decisionNote) || other.decisionNote == decisionNote)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,targetType,targetId,requestedLevel,reason,requesterId,requesterName,status,decidedBy,decidedByName,decidedAt,decisionNote,createdAt);

@override
String toString() {
  return 'AccessRequestRow(id: $id, targetType: $targetType, targetId: $targetId, requestedLevel: $requestedLevel, reason: $reason, requesterId: $requesterId, requesterName: $requesterName, status: $status, decidedBy: $decidedBy, decidedByName: $decidedByName, decidedAt: $decidedAt, decisionNote: $decisionNote, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AccessRequestRowCopyWith<$Res>  {
  factory $AccessRequestRowCopyWith(AccessRequestRow value, $Res Function(AccessRequestRow) _then) = _$AccessRequestRowCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'target_type') String targetType,@JsonKey(name: 'target_id') int targetId,@JsonKey(name: 'requested_level') String requestedLevel, String? reason,@JsonKey(name: 'requester_id') int requesterId,@JsonKey(name: 'requester_name') String? requesterName, String status,@JsonKey(name: 'decided_by') int? decidedBy,@JsonKey(name: 'decided_by_name') String? decidedByName,@JsonKey(name: 'decided_at') String? decidedAt,@JsonKey(name: 'decision_note') String? decisionNote,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class _$AccessRequestRowCopyWithImpl<$Res>
    implements $AccessRequestRowCopyWith<$Res> {
  _$AccessRequestRowCopyWithImpl(this._self, this._then);

  final AccessRequestRow _self;
  final $Res Function(AccessRequestRow) _then;

/// Create a copy of AccessRequestRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? targetType = null,Object? targetId = null,Object? requestedLevel = null,Object? reason = freezed,Object? requesterId = null,Object? requesterName = freezed,Object? status = null,Object? decidedBy = freezed,Object? decidedByName = freezed,Object? decidedAt = freezed,Object? decisionNote = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as int,requestedLevel: null == requestedLevel ? _self.requestedLevel : requestedLevel // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,requesterId: null == requesterId ? _self.requesterId : requesterId // ignore: cast_nullable_to_non_nullable
as int,requesterName: freezed == requesterName ? _self.requesterName : requesterName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,decidedBy: freezed == decidedBy ? _self.decidedBy : decidedBy // ignore: cast_nullable_to_non_nullable
as int?,decidedByName: freezed == decidedByName ? _self.decidedByName : decidedByName // ignore: cast_nullable_to_non_nullable
as String?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as String?,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AccessRequestRow].
extension AccessRequestRowPatterns on AccessRequestRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccessRequestRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccessRequestRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccessRequestRow value)  $default,){
final _that = this;
switch (_that) {
case _AccessRequestRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccessRequestRow value)?  $default,){
final _that = this;
switch (_that) {
case _AccessRequestRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'target_type')  String targetType, @JsonKey(name: 'target_id')  int targetId, @JsonKey(name: 'requested_level')  String requestedLevel,  String? reason, @JsonKey(name: 'requester_id')  int requesterId, @JsonKey(name: 'requester_name')  String? requesterName,  String status, @JsonKey(name: 'decided_by')  int? decidedBy, @JsonKey(name: 'decided_by_name')  String? decidedByName, @JsonKey(name: 'decided_at')  String? decidedAt, @JsonKey(name: 'decision_note')  String? decisionNote, @JsonKey(name: 'created_at')  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccessRequestRow() when $default != null:
return $default(_that.id,_that.targetType,_that.targetId,_that.requestedLevel,_that.reason,_that.requesterId,_that.requesterName,_that.status,_that.decidedBy,_that.decidedByName,_that.decidedAt,_that.decisionNote,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'target_type')  String targetType, @JsonKey(name: 'target_id')  int targetId, @JsonKey(name: 'requested_level')  String requestedLevel,  String? reason, @JsonKey(name: 'requester_id')  int requesterId, @JsonKey(name: 'requester_name')  String? requesterName,  String status, @JsonKey(name: 'decided_by')  int? decidedBy, @JsonKey(name: 'decided_by_name')  String? decidedByName, @JsonKey(name: 'decided_at')  String? decidedAt, @JsonKey(name: 'decision_note')  String? decisionNote, @JsonKey(name: 'created_at')  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _AccessRequestRow():
return $default(_that.id,_that.targetType,_that.targetId,_that.requestedLevel,_that.reason,_that.requesterId,_that.requesterName,_that.status,_that.decidedBy,_that.decidedByName,_that.decidedAt,_that.decisionNote,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'target_type')  String targetType, @JsonKey(name: 'target_id')  int targetId, @JsonKey(name: 'requested_level')  String requestedLevel,  String? reason, @JsonKey(name: 'requester_id')  int requesterId, @JsonKey(name: 'requester_name')  String? requesterName,  String status, @JsonKey(name: 'decided_by')  int? decidedBy, @JsonKey(name: 'decided_by_name')  String? decidedByName, @JsonKey(name: 'decided_at')  String? decidedAt, @JsonKey(name: 'decision_note')  String? decisionNote, @JsonKey(name: 'created_at')  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AccessRequestRow() when $default != null:
return $default(_that.id,_that.targetType,_that.targetId,_that.requestedLevel,_that.reason,_that.requesterId,_that.requesterName,_that.status,_that.decidedBy,_that.decidedByName,_that.decidedAt,_that.decisionNote,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccessRequestRow implements AccessRequestRow {
  const _AccessRequestRow({required this.id, @JsonKey(name: 'target_type') required this.targetType, @JsonKey(name: 'target_id') required this.targetId, @JsonKey(name: 'requested_level') required this.requestedLevel, this.reason, @JsonKey(name: 'requester_id') required this.requesterId, @JsonKey(name: 'requester_name') this.requesterName, required this.status, @JsonKey(name: 'decided_by') this.decidedBy, @JsonKey(name: 'decided_by_name') this.decidedByName, @JsonKey(name: 'decided_at') this.decidedAt, @JsonKey(name: 'decision_note') this.decisionNote, @JsonKey(name: 'created_at') this.createdAt});
  factory _AccessRequestRow.fromJson(Map<String, dynamic> json) => _$AccessRequestRowFromJson(json);

@override final  int id;
@override@JsonKey(name: 'target_type') final  String targetType;
@override@JsonKey(name: 'target_id') final  int targetId;
@override@JsonKey(name: 'requested_level') final  String requestedLevel;
@override final  String? reason;
@override@JsonKey(name: 'requester_id') final  int requesterId;
@override@JsonKey(name: 'requester_name') final  String? requesterName;
@override final  String status;
@override@JsonKey(name: 'decided_by') final  int? decidedBy;
@override@JsonKey(name: 'decided_by_name') final  String? decidedByName;
@override@JsonKey(name: 'decided_at') final  String? decidedAt;
@override@JsonKey(name: 'decision_note') final  String? decisionNote;
@override@JsonKey(name: 'created_at') final  String? createdAt;

/// Create a copy of AccessRequestRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccessRequestRowCopyWith<_AccessRequestRow> get copyWith => __$AccessRequestRowCopyWithImpl<_AccessRequestRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccessRequestRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccessRequestRow&&(identical(other.id, id) || other.id == id)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.requestedLevel, requestedLevel) || other.requestedLevel == requestedLevel)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.requesterId, requesterId) || other.requesterId == requesterId)&&(identical(other.requesterName, requesterName) || other.requesterName == requesterName)&&(identical(other.status, status) || other.status == status)&&(identical(other.decidedBy, decidedBy) || other.decidedBy == decidedBy)&&(identical(other.decidedByName, decidedByName) || other.decidedByName == decidedByName)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.decisionNote, decisionNote) || other.decisionNote == decisionNote)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,targetType,targetId,requestedLevel,reason,requesterId,requesterName,status,decidedBy,decidedByName,decidedAt,decisionNote,createdAt);

@override
String toString() {
  return 'AccessRequestRow(id: $id, targetType: $targetType, targetId: $targetId, requestedLevel: $requestedLevel, reason: $reason, requesterId: $requesterId, requesterName: $requesterName, status: $status, decidedBy: $decidedBy, decidedByName: $decidedByName, decidedAt: $decidedAt, decisionNote: $decisionNote, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AccessRequestRowCopyWith<$Res> implements $AccessRequestRowCopyWith<$Res> {
  factory _$AccessRequestRowCopyWith(_AccessRequestRow value, $Res Function(_AccessRequestRow) _then) = __$AccessRequestRowCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'target_type') String targetType,@JsonKey(name: 'target_id') int targetId,@JsonKey(name: 'requested_level') String requestedLevel, String? reason,@JsonKey(name: 'requester_id') int requesterId,@JsonKey(name: 'requester_name') String? requesterName, String status,@JsonKey(name: 'decided_by') int? decidedBy,@JsonKey(name: 'decided_by_name') String? decidedByName,@JsonKey(name: 'decided_at') String? decidedAt,@JsonKey(name: 'decision_note') String? decisionNote,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class __$AccessRequestRowCopyWithImpl<$Res>
    implements _$AccessRequestRowCopyWith<$Res> {
  __$AccessRequestRowCopyWithImpl(this._self, this._then);

  final _AccessRequestRow _self;
  final $Res Function(_AccessRequestRow) _then;

/// Create a copy of AccessRequestRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? targetType = null,Object? targetId = null,Object? requestedLevel = null,Object? reason = freezed,Object? requesterId = null,Object? requesterName = freezed,Object? status = null,Object? decidedBy = freezed,Object? decidedByName = freezed,Object? decidedAt = freezed,Object? decisionNote = freezed,Object? createdAt = freezed,}) {
  return _then(_AccessRequestRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as int,requestedLevel: null == requestedLevel ? _self.requestedLevel : requestedLevel // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,requesterId: null == requesterId ? _self.requesterId : requesterId // ignore: cast_nullable_to_non_nullable
as int,requesterName: freezed == requesterName ? _self.requesterName : requesterName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,decidedBy: freezed == decidedBy ? _self.decidedBy : decidedBy // ignore: cast_nullable_to_non_nullable
as int?,decidedByName: freezed == decidedByName ? _self.decidedByName : decidedByName // ignore: cast_nullable_to_non_nullable
as String?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as String?,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
