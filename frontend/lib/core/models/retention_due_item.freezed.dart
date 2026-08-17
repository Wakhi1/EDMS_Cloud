// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'retention_due_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RetentionDueItem {

 int get id;@JsonKey(name: 'record_no') String get recordNo; String get title;@JsonKey(name: 'retention_due_at') String get retentionDueAt;@JsonKey(name: 'disposal_action') String get disposalAction;@JsonKey(name: 'retention_class_name') String? get retentionClassName;
/// Create a copy of RetentionDueItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RetentionDueItemCopyWith<RetentionDueItem> get copyWith => _$RetentionDueItemCopyWithImpl<RetentionDueItem>(this as RetentionDueItem, _$identity);

  /// Serializes this RetentionDueItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RetentionDueItem&&(identical(other.id, id) || other.id == id)&&(identical(other.recordNo, recordNo) || other.recordNo == recordNo)&&(identical(other.title, title) || other.title == title)&&(identical(other.retentionDueAt, retentionDueAt) || other.retentionDueAt == retentionDueAt)&&(identical(other.disposalAction, disposalAction) || other.disposalAction == disposalAction)&&(identical(other.retentionClassName, retentionClassName) || other.retentionClassName == retentionClassName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,recordNo,title,retentionDueAt,disposalAction,retentionClassName);

@override
String toString() {
  return 'RetentionDueItem(id: $id, recordNo: $recordNo, title: $title, retentionDueAt: $retentionDueAt, disposalAction: $disposalAction, retentionClassName: $retentionClassName)';
}


}

/// @nodoc
abstract mixin class $RetentionDueItemCopyWith<$Res>  {
  factory $RetentionDueItemCopyWith(RetentionDueItem value, $Res Function(RetentionDueItem) _then) = _$RetentionDueItemCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'record_no') String recordNo, String title,@JsonKey(name: 'retention_due_at') String retentionDueAt,@JsonKey(name: 'disposal_action') String disposalAction,@JsonKey(name: 'retention_class_name') String? retentionClassName
});




}
/// @nodoc
class _$RetentionDueItemCopyWithImpl<$Res>
    implements $RetentionDueItemCopyWith<$Res> {
  _$RetentionDueItemCopyWithImpl(this._self, this._then);

  final RetentionDueItem _self;
  final $Res Function(RetentionDueItem) _then;

/// Create a copy of RetentionDueItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? recordNo = null,Object? title = null,Object? retentionDueAt = null,Object? disposalAction = null,Object? retentionClassName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,recordNo: null == recordNo ? _self.recordNo : recordNo // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,retentionDueAt: null == retentionDueAt ? _self.retentionDueAt : retentionDueAt // ignore: cast_nullable_to_non_nullable
as String,disposalAction: null == disposalAction ? _self.disposalAction : disposalAction // ignore: cast_nullable_to_non_nullable
as String,retentionClassName: freezed == retentionClassName ? _self.retentionClassName : retentionClassName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RetentionDueItem].
extension RetentionDueItemPatterns on RetentionDueItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RetentionDueItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RetentionDueItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RetentionDueItem value)  $default,){
final _that = this;
switch (_that) {
case _RetentionDueItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RetentionDueItem value)?  $default,){
final _that = this;
switch (_that) {
case _RetentionDueItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'record_no')  String recordNo,  String title, @JsonKey(name: 'retention_due_at')  String retentionDueAt, @JsonKey(name: 'disposal_action')  String disposalAction, @JsonKey(name: 'retention_class_name')  String? retentionClassName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RetentionDueItem() when $default != null:
return $default(_that.id,_that.recordNo,_that.title,_that.retentionDueAt,_that.disposalAction,_that.retentionClassName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'record_no')  String recordNo,  String title, @JsonKey(name: 'retention_due_at')  String retentionDueAt, @JsonKey(name: 'disposal_action')  String disposalAction, @JsonKey(name: 'retention_class_name')  String? retentionClassName)  $default,) {final _that = this;
switch (_that) {
case _RetentionDueItem():
return $default(_that.id,_that.recordNo,_that.title,_that.retentionDueAt,_that.disposalAction,_that.retentionClassName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'record_no')  String recordNo,  String title, @JsonKey(name: 'retention_due_at')  String retentionDueAt, @JsonKey(name: 'disposal_action')  String disposalAction, @JsonKey(name: 'retention_class_name')  String? retentionClassName)?  $default,) {final _that = this;
switch (_that) {
case _RetentionDueItem() when $default != null:
return $default(_that.id,_that.recordNo,_that.title,_that.retentionDueAt,_that.disposalAction,_that.retentionClassName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RetentionDueItem implements RetentionDueItem {
  const _RetentionDueItem({required this.id, @JsonKey(name: 'record_no') required this.recordNo, required this.title, @JsonKey(name: 'retention_due_at') required this.retentionDueAt, @JsonKey(name: 'disposal_action') required this.disposalAction, @JsonKey(name: 'retention_class_name') this.retentionClassName});
  factory _RetentionDueItem.fromJson(Map<String, dynamic> json) => _$RetentionDueItemFromJson(json);

@override final  int id;
@override@JsonKey(name: 'record_no') final  String recordNo;
@override final  String title;
@override@JsonKey(name: 'retention_due_at') final  String retentionDueAt;
@override@JsonKey(name: 'disposal_action') final  String disposalAction;
@override@JsonKey(name: 'retention_class_name') final  String? retentionClassName;

/// Create a copy of RetentionDueItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RetentionDueItemCopyWith<_RetentionDueItem> get copyWith => __$RetentionDueItemCopyWithImpl<_RetentionDueItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RetentionDueItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RetentionDueItem&&(identical(other.id, id) || other.id == id)&&(identical(other.recordNo, recordNo) || other.recordNo == recordNo)&&(identical(other.title, title) || other.title == title)&&(identical(other.retentionDueAt, retentionDueAt) || other.retentionDueAt == retentionDueAt)&&(identical(other.disposalAction, disposalAction) || other.disposalAction == disposalAction)&&(identical(other.retentionClassName, retentionClassName) || other.retentionClassName == retentionClassName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,recordNo,title,retentionDueAt,disposalAction,retentionClassName);

@override
String toString() {
  return 'RetentionDueItem(id: $id, recordNo: $recordNo, title: $title, retentionDueAt: $retentionDueAt, disposalAction: $disposalAction, retentionClassName: $retentionClassName)';
}


}

/// @nodoc
abstract mixin class _$RetentionDueItemCopyWith<$Res> implements $RetentionDueItemCopyWith<$Res> {
  factory _$RetentionDueItemCopyWith(_RetentionDueItem value, $Res Function(_RetentionDueItem) _then) = __$RetentionDueItemCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'record_no') String recordNo, String title,@JsonKey(name: 'retention_due_at') String retentionDueAt,@JsonKey(name: 'disposal_action') String disposalAction,@JsonKey(name: 'retention_class_name') String? retentionClassName
});




}
/// @nodoc
class __$RetentionDueItemCopyWithImpl<$Res>
    implements _$RetentionDueItemCopyWith<$Res> {
  __$RetentionDueItemCopyWithImpl(this._self, this._then);

  final _RetentionDueItem _self;
  final $Res Function(_RetentionDueItem) _then;

/// Create a copy of RetentionDueItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? recordNo = null,Object? title = null,Object? retentionDueAt = null,Object? disposalAction = null,Object? retentionClassName = freezed,}) {
  return _then(_RetentionDueItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,recordNo: null == recordNo ? _self.recordNo : recordNo // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,retentionDueAt: null == retentionDueAt ? _self.retentionDueAt : retentionDueAt // ignore: cast_nullable_to_non_nullable
as String,disposalAction: null == disposalAction ? _self.disposalAction : disposalAction // ignore: cast_nullable_to_non_nullable
as String,retentionClassName: freezed == retentionClassName ? _self.retentionClassName : retentionClassName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
