// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'approval_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApprovalItem {

@JsonKey(name: 'approval_id') int get approvalId;@JsonKey(name: 'instance_id') int get instanceId;@JsonKey(name: 'step_id') int get stepId;@JsonKey(name: 'document_id') int get documentId;@JsonKey(name: 'record_no') String get recordNo; String get title;@JsonKey(name: 'step_name') String get stepName;@JsonKey(name: 'sla_days') int? get slaDays;@JsonKey(name: 'started_at') String? get startedAt;@JsonKey(name: 'escalated_at') String? get escalatedAt;
/// Create a copy of ApprovalItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApprovalItemCopyWith<ApprovalItem> get copyWith => _$ApprovalItemCopyWithImpl<ApprovalItem>(this as ApprovalItem, _$identity);

  /// Serializes this ApprovalItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApprovalItem&&(identical(other.approvalId, approvalId) || other.approvalId == approvalId)&&(identical(other.instanceId, instanceId) || other.instanceId == instanceId)&&(identical(other.stepId, stepId) || other.stepId == stepId)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.recordNo, recordNo) || other.recordNo == recordNo)&&(identical(other.title, title) || other.title == title)&&(identical(other.stepName, stepName) || other.stepName == stepName)&&(identical(other.slaDays, slaDays) || other.slaDays == slaDays)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.escalatedAt, escalatedAt) || other.escalatedAt == escalatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,approvalId,instanceId,stepId,documentId,recordNo,title,stepName,slaDays,startedAt,escalatedAt);

@override
String toString() {
  return 'ApprovalItem(approvalId: $approvalId, instanceId: $instanceId, stepId: $stepId, documentId: $documentId, recordNo: $recordNo, title: $title, stepName: $stepName, slaDays: $slaDays, startedAt: $startedAt, escalatedAt: $escalatedAt)';
}


}

/// @nodoc
abstract mixin class $ApprovalItemCopyWith<$Res>  {
  factory $ApprovalItemCopyWith(ApprovalItem value, $Res Function(ApprovalItem) _then) = _$ApprovalItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'approval_id') int approvalId,@JsonKey(name: 'instance_id') int instanceId,@JsonKey(name: 'step_id') int stepId,@JsonKey(name: 'document_id') int documentId,@JsonKey(name: 'record_no') String recordNo, String title,@JsonKey(name: 'step_name') String stepName,@JsonKey(name: 'sla_days') int? slaDays,@JsonKey(name: 'started_at') String? startedAt,@JsonKey(name: 'escalated_at') String? escalatedAt
});




}
/// @nodoc
class _$ApprovalItemCopyWithImpl<$Res>
    implements $ApprovalItemCopyWith<$Res> {
  _$ApprovalItemCopyWithImpl(this._self, this._then);

  final ApprovalItem _self;
  final $Res Function(ApprovalItem) _then;

/// Create a copy of ApprovalItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? approvalId = null,Object? instanceId = null,Object? stepId = null,Object? documentId = null,Object? recordNo = null,Object? title = null,Object? stepName = null,Object? slaDays = freezed,Object? startedAt = freezed,Object? escalatedAt = freezed,}) {
  return _then(_self.copyWith(
approvalId: null == approvalId ? _self.approvalId : approvalId // ignore: cast_nullable_to_non_nullable
as int,instanceId: null == instanceId ? _self.instanceId : instanceId // ignore: cast_nullable_to_non_nullable
as int,stepId: null == stepId ? _self.stepId : stepId // ignore: cast_nullable_to_non_nullable
as int,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as int,recordNo: null == recordNo ? _self.recordNo : recordNo // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,stepName: null == stepName ? _self.stepName : stepName // ignore: cast_nullable_to_non_nullable
as String,slaDays: freezed == slaDays ? _self.slaDays : slaDays // ignore: cast_nullable_to_non_nullable
as int?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,escalatedAt: freezed == escalatedAt ? _self.escalatedAt : escalatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ApprovalItem].
extension ApprovalItemPatterns on ApprovalItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApprovalItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApprovalItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApprovalItem value)  $default,){
final _that = this;
switch (_that) {
case _ApprovalItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApprovalItem value)?  $default,){
final _that = this;
switch (_that) {
case _ApprovalItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'approval_id')  int approvalId, @JsonKey(name: 'instance_id')  int instanceId, @JsonKey(name: 'step_id')  int stepId, @JsonKey(name: 'document_id')  int documentId, @JsonKey(name: 'record_no')  String recordNo,  String title, @JsonKey(name: 'step_name')  String stepName, @JsonKey(name: 'sla_days')  int? slaDays, @JsonKey(name: 'started_at')  String? startedAt, @JsonKey(name: 'escalated_at')  String? escalatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApprovalItem() when $default != null:
return $default(_that.approvalId,_that.instanceId,_that.stepId,_that.documentId,_that.recordNo,_that.title,_that.stepName,_that.slaDays,_that.startedAt,_that.escalatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'approval_id')  int approvalId, @JsonKey(name: 'instance_id')  int instanceId, @JsonKey(name: 'step_id')  int stepId, @JsonKey(name: 'document_id')  int documentId, @JsonKey(name: 'record_no')  String recordNo,  String title, @JsonKey(name: 'step_name')  String stepName, @JsonKey(name: 'sla_days')  int? slaDays, @JsonKey(name: 'started_at')  String? startedAt, @JsonKey(name: 'escalated_at')  String? escalatedAt)  $default,) {final _that = this;
switch (_that) {
case _ApprovalItem():
return $default(_that.approvalId,_that.instanceId,_that.stepId,_that.documentId,_that.recordNo,_that.title,_that.stepName,_that.slaDays,_that.startedAt,_that.escalatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'approval_id')  int approvalId, @JsonKey(name: 'instance_id')  int instanceId, @JsonKey(name: 'step_id')  int stepId, @JsonKey(name: 'document_id')  int documentId, @JsonKey(name: 'record_no')  String recordNo,  String title, @JsonKey(name: 'step_name')  String stepName, @JsonKey(name: 'sla_days')  int? slaDays, @JsonKey(name: 'started_at')  String? startedAt, @JsonKey(name: 'escalated_at')  String? escalatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ApprovalItem() when $default != null:
return $default(_that.approvalId,_that.instanceId,_that.stepId,_that.documentId,_that.recordNo,_that.title,_that.stepName,_that.slaDays,_that.startedAt,_that.escalatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApprovalItem implements ApprovalItem {
  const _ApprovalItem({@JsonKey(name: 'approval_id') required this.approvalId, @JsonKey(name: 'instance_id') required this.instanceId, @JsonKey(name: 'step_id') required this.stepId, @JsonKey(name: 'document_id') required this.documentId, @JsonKey(name: 'record_no') required this.recordNo, required this.title, @JsonKey(name: 'step_name') required this.stepName, @JsonKey(name: 'sla_days') this.slaDays, @JsonKey(name: 'started_at') this.startedAt, @JsonKey(name: 'escalated_at') this.escalatedAt});
  factory _ApprovalItem.fromJson(Map<String, dynamic> json) => _$ApprovalItemFromJson(json);

@override@JsonKey(name: 'approval_id') final  int approvalId;
@override@JsonKey(name: 'instance_id') final  int instanceId;
@override@JsonKey(name: 'step_id') final  int stepId;
@override@JsonKey(name: 'document_id') final  int documentId;
@override@JsonKey(name: 'record_no') final  String recordNo;
@override final  String title;
@override@JsonKey(name: 'step_name') final  String stepName;
@override@JsonKey(name: 'sla_days') final  int? slaDays;
@override@JsonKey(name: 'started_at') final  String? startedAt;
@override@JsonKey(name: 'escalated_at') final  String? escalatedAt;

/// Create a copy of ApprovalItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApprovalItemCopyWith<_ApprovalItem> get copyWith => __$ApprovalItemCopyWithImpl<_ApprovalItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApprovalItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApprovalItem&&(identical(other.approvalId, approvalId) || other.approvalId == approvalId)&&(identical(other.instanceId, instanceId) || other.instanceId == instanceId)&&(identical(other.stepId, stepId) || other.stepId == stepId)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.recordNo, recordNo) || other.recordNo == recordNo)&&(identical(other.title, title) || other.title == title)&&(identical(other.stepName, stepName) || other.stepName == stepName)&&(identical(other.slaDays, slaDays) || other.slaDays == slaDays)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.escalatedAt, escalatedAt) || other.escalatedAt == escalatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,approvalId,instanceId,stepId,documentId,recordNo,title,stepName,slaDays,startedAt,escalatedAt);

@override
String toString() {
  return 'ApprovalItem(approvalId: $approvalId, instanceId: $instanceId, stepId: $stepId, documentId: $documentId, recordNo: $recordNo, title: $title, stepName: $stepName, slaDays: $slaDays, startedAt: $startedAt, escalatedAt: $escalatedAt)';
}


}

/// @nodoc
abstract mixin class _$ApprovalItemCopyWith<$Res> implements $ApprovalItemCopyWith<$Res> {
  factory _$ApprovalItemCopyWith(_ApprovalItem value, $Res Function(_ApprovalItem) _then) = __$ApprovalItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'approval_id') int approvalId,@JsonKey(name: 'instance_id') int instanceId,@JsonKey(name: 'step_id') int stepId,@JsonKey(name: 'document_id') int documentId,@JsonKey(name: 'record_no') String recordNo, String title,@JsonKey(name: 'step_name') String stepName,@JsonKey(name: 'sla_days') int? slaDays,@JsonKey(name: 'started_at') String? startedAt,@JsonKey(name: 'escalated_at') String? escalatedAt
});




}
/// @nodoc
class __$ApprovalItemCopyWithImpl<$Res>
    implements _$ApprovalItemCopyWith<$Res> {
  __$ApprovalItemCopyWithImpl(this._self, this._then);

  final _ApprovalItem _self;
  final $Res Function(_ApprovalItem) _then;

/// Create a copy of ApprovalItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? approvalId = null,Object? instanceId = null,Object? stepId = null,Object? documentId = null,Object? recordNo = null,Object? title = null,Object? stepName = null,Object? slaDays = freezed,Object? startedAt = freezed,Object? escalatedAt = freezed,}) {
  return _then(_ApprovalItem(
approvalId: null == approvalId ? _self.approvalId : approvalId // ignore: cast_nullable_to_non_nullable
as int,instanceId: null == instanceId ? _self.instanceId : instanceId // ignore: cast_nullable_to_non_nullable
as int,stepId: null == stepId ? _self.stepId : stepId // ignore: cast_nullable_to_non_nullable
as int,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as int,recordNo: null == recordNo ? _self.recordNo : recordNo // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,stepName: null == stepName ? _self.stepName : stepName // ignore: cast_nullable_to_non_nullable
as String,slaDays: freezed == slaDays ? _self.slaDays : slaDays // ignore: cast_nullable_to_non_nullable
as int?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,escalatedAt: freezed == escalatedAt ? _self.escalatedAt : escalatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
