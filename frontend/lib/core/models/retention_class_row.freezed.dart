// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'retention_class_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RetentionClassRow {

 int get id; String get code; String get name;@JsonKey(name: 'retention_years') int get retentionYears;@JsonKey(name: 'trigger_event') String? get triggerEvent;@JsonKey(name: 'disposal_action') String get disposalAction;@JsonKey(name: 'requires_records_manager_approval', fromJson: _boolFromInt) bool get requiresRecordsManagerApproval;@JsonKey(name: 'created_at') String? get createdAt;
/// Create a copy of RetentionClassRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RetentionClassRowCopyWith<RetentionClassRow> get copyWith => _$RetentionClassRowCopyWithImpl<RetentionClassRow>(this as RetentionClassRow, _$identity);

  /// Serializes this RetentionClassRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RetentionClassRow&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.retentionYears, retentionYears) || other.retentionYears == retentionYears)&&(identical(other.triggerEvent, triggerEvent) || other.triggerEvent == triggerEvent)&&(identical(other.disposalAction, disposalAction) || other.disposalAction == disposalAction)&&(identical(other.requiresRecordsManagerApproval, requiresRecordsManagerApproval) || other.requiresRecordsManagerApproval == requiresRecordsManagerApproval)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,retentionYears,triggerEvent,disposalAction,requiresRecordsManagerApproval,createdAt);

@override
String toString() {
  return 'RetentionClassRow(id: $id, code: $code, name: $name, retentionYears: $retentionYears, triggerEvent: $triggerEvent, disposalAction: $disposalAction, requiresRecordsManagerApproval: $requiresRecordsManagerApproval, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $RetentionClassRowCopyWith<$Res>  {
  factory $RetentionClassRowCopyWith(RetentionClassRow value, $Res Function(RetentionClassRow) _then) = _$RetentionClassRowCopyWithImpl;
@useResult
$Res call({
 int id, String code, String name,@JsonKey(name: 'retention_years') int retentionYears,@JsonKey(name: 'trigger_event') String? triggerEvent,@JsonKey(name: 'disposal_action') String disposalAction,@JsonKey(name: 'requires_records_manager_approval', fromJson: _boolFromInt) bool requiresRecordsManagerApproval,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class _$RetentionClassRowCopyWithImpl<$Res>
    implements $RetentionClassRowCopyWith<$Res> {
  _$RetentionClassRowCopyWithImpl(this._self, this._then);

  final RetentionClassRow _self;
  final $Res Function(RetentionClassRow) _then;

/// Create a copy of RetentionClassRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? retentionYears = null,Object? triggerEvent = freezed,Object? disposalAction = null,Object? requiresRecordsManagerApproval = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,retentionYears: null == retentionYears ? _self.retentionYears : retentionYears // ignore: cast_nullable_to_non_nullable
as int,triggerEvent: freezed == triggerEvent ? _self.triggerEvent : triggerEvent // ignore: cast_nullable_to_non_nullable
as String?,disposalAction: null == disposalAction ? _self.disposalAction : disposalAction // ignore: cast_nullable_to_non_nullable
as String,requiresRecordsManagerApproval: null == requiresRecordsManagerApproval ? _self.requiresRecordsManagerApproval : requiresRecordsManagerApproval // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RetentionClassRow].
extension RetentionClassRowPatterns on RetentionClassRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RetentionClassRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RetentionClassRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RetentionClassRow value)  $default,){
final _that = this;
switch (_that) {
case _RetentionClassRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RetentionClassRow value)?  $default,){
final _that = this;
switch (_that) {
case _RetentionClassRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String name, @JsonKey(name: 'retention_years')  int retentionYears, @JsonKey(name: 'trigger_event')  String? triggerEvent, @JsonKey(name: 'disposal_action')  String disposalAction, @JsonKey(name: 'requires_records_manager_approval', fromJson: _boolFromInt)  bool requiresRecordsManagerApproval, @JsonKey(name: 'created_at')  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RetentionClassRow() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.retentionYears,_that.triggerEvent,_that.disposalAction,_that.requiresRecordsManagerApproval,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String name, @JsonKey(name: 'retention_years')  int retentionYears, @JsonKey(name: 'trigger_event')  String? triggerEvent, @JsonKey(name: 'disposal_action')  String disposalAction, @JsonKey(name: 'requires_records_manager_approval', fromJson: _boolFromInt)  bool requiresRecordsManagerApproval, @JsonKey(name: 'created_at')  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _RetentionClassRow():
return $default(_that.id,_that.code,_that.name,_that.retentionYears,_that.triggerEvent,_that.disposalAction,_that.requiresRecordsManagerApproval,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String name, @JsonKey(name: 'retention_years')  int retentionYears, @JsonKey(name: 'trigger_event')  String? triggerEvent, @JsonKey(name: 'disposal_action')  String disposalAction, @JsonKey(name: 'requires_records_manager_approval', fromJson: _boolFromInt)  bool requiresRecordsManagerApproval, @JsonKey(name: 'created_at')  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _RetentionClassRow() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.retentionYears,_that.triggerEvent,_that.disposalAction,_that.requiresRecordsManagerApproval,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RetentionClassRow implements RetentionClassRow {
  const _RetentionClassRow({required this.id, required this.code, required this.name, @JsonKey(name: 'retention_years') required this.retentionYears, @JsonKey(name: 'trigger_event') this.triggerEvent, @JsonKey(name: 'disposal_action') required this.disposalAction, @JsonKey(name: 'requires_records_manager_approval', fromJson: _boolFromInt) required this.requiresRecordsManagerApproval, @JsonKey(name: 'created_at') this.createdAt});
  factory _RetentionClassRow.fromJson(Map<String, dynamic> json) => _$RetentionClassRowFromJson(json);

@override final  int id;
@override final  String code;
@override final  String name;
@override@JsonKey(name: 'retention_years') final  int retentionYears;
@override@JsonKey(name: 'trigger_event') final  String? triggerEvent;
@override@JsonKey(name: 'disposal_action') final  String disposalAction;
@override@JsonKey(name: 'requires_records_manager_approval', fromJson: _boolFromInt) final  bool requiresRecordsManagerApproval;
@override@JsonKey(name: 'created_at') final  String? createdAt;

/// Create a copy of RetentionClassRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RetentionClassRowCopyWith<_RetentionClassRow> get copyWith => __$RetentionClassRowCopyWithImpl<_RetentionClassRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RetentionClassRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RetentionClassRow&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.retentionYears, retentionYears) || other.retentionYears == retentionYears)&&(identical(other.triggerEvent, triggerEvent) || other.triggerEvent == triggerEvent)&&(identical(other.disposalAction, disposalAction) || other.disposalAction == disposalAction)&&(identical(other.requiresRecordsManagerApproval, requiresRecordsManagerApproval) || other.requiresRecordsManagerApproval == requiresRecordsManagerApproval)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,retentionYears,triggerEvent,disposalAction,requiresRecordsManagerApproval,createdAt);

@override
String toString() {
  return 'RetentionClassRow(id: $id, code: $code, name: $name, retentionYears: $retentionYears, triggerEvent: $triggerEvent, disposalAction: $disposalAction, requiresRecordsManagerApproval: $requiresRecordsManagerApproval, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$RetentionClassRowCopyWith<$Res> implements $RetentionClassRowCopyWith<$Res> {
  factory _$RetentionClassRowCopyWith(_RetentionClassRow value, $Res Function(_RetentionClassRow) _then) = __$RetentionClassRowCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String name,@JsonKey(name: 'retention_years') int retentionYears,@JsonKey(name: 'trigger_event') String? triggerEvent,@JsonKey(name: 'disposal_action') String disposalAction,@JsonKey(name: 'requires_records_manager_approval', fromJson: _boolFromInt) bool requiresRecordsManagerApproval,@JsonKey(name: 'created_at') String? createdAt
});




}
/// @nodoc
class __$RetentionClassRowCopyWithImpl<$Res>
    implements _$RetentionClassRowCopyWith<$Res> {
  __$RetentionClassRowCopyWithImpl(this._self, this._then);

  final _RetentionClassRow _self;
  final $Res Function(_RetentionClassRow) _then;

/// Create a copy of RetentionClassRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? retentionYears = null,Object? triggerEvent = freezed,Object? disposalAction = null,Object? requiresRecordsManagerApproval = null,Object? createdAt = freezed,}) {
  return _then(_RetentionClassRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,retentionYears: null == retentionYears ? _self.retentionYears : retentionYears // ignore: cast_nullable_to_non_nullable
as int,triggerEvent: freezed == triggerEvent ? _self.triggerEvent : triggerEvent // ignore: cast_nullable_to_non_nullable
as String?,disposalAction: null == disposalAction ? _self.disposalAction : disposalAction // ignore: cast_nullable_to_non_nullable
as String,requiresRecordsManagerApproval: null == requiresRecordsManagerApproval ? _self.requiresRecordsManagerApproval : requiresRecordsManagerApproval // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
