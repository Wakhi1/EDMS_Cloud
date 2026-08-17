// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'integration_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IntegrationRow {

 String get id; String get name; String? get description; String? get endpoint; String get status;@JsonKey(name: 'last_sync_at') String? get lastSyncAt;@JsonKey(name: 'updated_at') String? get updatedAt;@JsonKey(name: 'config_json', fromJson: _configJsonFromJson) Map<String, dynamic>? get configJson;
/// Create a copy of IntegrationRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntegrationRowCopyWith<IntegrationRow> get copyWith => _$IntegrationRowCopyWithImpl<IntegrationRow>(this as IntegrationRow, _$identity);

  /// Serializes this IntegrationRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IntegrationRow&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastSyncAt, lastSyncAt) || other.lastSyncAt == lastSyncAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.configJson, configJson));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,endpoint,status,lastSyncAt,updatedAt,const DeepCollectionEquality().hash(configJson));

@override
String toString() {
  return 'IntegrationRow(id: $id, name: $name, description: $description, endpoint: $endpoint, status: $status, lastSyncAt: $lastSyncAt, updatedAt: $updatedAt, configJson: $configJson)';
}


}

/// @nodoc
abstract mixin class $IntegrationRowCopyWith<$Res>  {
  factory $IntegrationRowCopyWith(IntegrationRow value, $Res Function(IntegrationRow) _then) = _$IntegrationRowCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, String? endpoint, String status,@JsonKey(name: 'last_sync_at') String? lastSyncAt,@JsonKey(name: 'updated_at') String? updatedAt,@JsonKey(name: 'config_json', fromJson: _configJsonFromJson) Map<String, dynamic>? configJson
});




}
/// @nodoc
class _$IntegrationRowCopyWithImpl<$Res>
    implements $IntegrationRowCopyWith<$Res> {
  _$IntegrationRowCopyWithImpl(this._self, this._then);

  final IntegrationRow _self;
  final $Res Function(IntegrationRow) _then;

/// Create a copy of IntegrationRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? endpoint = freezed,Object? status = null,Object? lastSyncAt = freezed,Object? updatedAt = freezed,Object? configJson = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,endpoint: freezed == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,lastSyncAt: freezed == lastSyncAt ? _self.lastSyncAt : lastSyncAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,configJson: freezed == configJson ? _self.configJson : configJson // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [IntegrationRow].
extension IntegrationRowPatterns on IntegrationRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IntegrationRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IntegrationRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IntegrationRow value)  $default,){
final _that = this;
switch (_that) {
case _IntegrationRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IntegrationRow value)?  $default,){
final _that = this;
switch (_that) {
case _IntegrationRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String? endpoint,  String status, @JsonKey(name: 'last_sync_at')  String? lastSyncAt, @JsonKey(name: 'updated_at')  String? updatedAt, @JsonKey(name: 'config_json', fromJson: _configJsonFromJson)  Map<String, dynamic>? configJson)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IntegrationRow() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.endpoint,_that.status,_that.lastSyncAt,_that.updatedAt,_that.configJson);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String? endpoint,  String status, @JsonKey(name: 'last_sync_at')  String? lastSyncAt, @JsonKey(name: 'updated_at')  String? updatedAt, @JsonKey(name: 'config_json', fromJson: _configJsonFromJson)  Map<String, dynamic>? configJson)  $default,) {final _that = this;
switch (_that) {
case _IntegrationRow():
return $default(_that.id,_that.name,_that.description,_that.endpoint,_that.status,_that.lastSyncAt,_that.updatedAt,_that.configJson);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  String? endpoint,  String status, @JsonKey(name: 'last_sync_at')  String? lastSyncAt, @JsonKey(name: 'updated_at')  String? updatedAt, @JsonKey(name: 'config_json', fromJson: _configJsonFromJson)  Map<String, dynamic>? configJson)?  $default,) {final _that = this;
switch (_that) {
case _IntegrationRow() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.endpoint,_that.status,_that.lastSyncAt,_that.updatedAt,_that.configJson);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IntegrationRow implements IntegrationRow {
  const _IntegrationRow({required this.id, required this.name, this.description, this.endpoint, required this.status, @JsonKey(name: 'last_sync_at') this.lastSyncAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'config_json', fromJson: _configJsonFromJson) final  Map<String, dynamic>? configJson}): _configJson = configJson;
  factory _IntegrationRow.fromJson(Map<String, dynamic> json) => _$IntegrationRowFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? description;
@override final  String? endpoint;
@override final  String status;
@override@JsonKey(name: 'last_sync_at') final  String? lastSyncAt;
@override@JsonKey(name: 'updated_at') final  String? updatedAt;
 final  Map<String, dynamic>? _configJson;
@override@JsonKey(name: 'config_json', fromJson: _configJsonFromJson) Map<String, dynamic>? get configJson {
  final value = _configJson;
  if (value == null) return null;
  if (_configJson is EqualUnmodifiableMapView) return _configJson;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of IntegrationRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IntegrationRowCopyWith<_IntegrationRow> get copyWith => __$IntegrationRowCopyWithImpl<_IntegrationRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IntegrationRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IntegrationRow&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastSyncAt, lastSyncAt) || other.lastSyncAt == lastSyncAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._configJson, _configJson));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,endpoint,status,lastSyncAt,updatedAt,const DeepCollectionEquality().hash(_configJson));

@override
String toString() {
  return 'IntegrationRow(id: $id, name: $name, description: $description, endpoint: $endpoint, status: $status, lastSyncAt: $lastSyncAt, updatedAt: $updatedAt, configJson: $configJson)';
}


}

/// @nodoc
abstract mixin class _$IntegrationRowCopyWith<$Res> implements $IntegrationRowCopyWith<$Res> {
  factory _$IntegrationRowCopyWith(_IntegrationRow value, $Res Function(_IntegrationRow) _then) = __$IntegrationRowCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, String? endpoint, String status,@JsonKey(name: 'last_sync_at') String? lastSyncAt,@JsonKey(name: 'updated_at') String? updatedAt,@JsonKey(name: 'config_json', fromJson: _configJsonFromJson) Map<String, dynamic>? configJson
});




}
/// @nodoc
class __$IntegrationRowCopyWithImpl<$Res>
    implements _$IntegrationRowCopyWith<$Res> {
  __$IntegrationRowCopyWithImpl(this._self, this._then);

  final _IntegrationRow _self;
  final $Res Function(_IntegrationRow) _then;

/// Create a copy of IntegrationRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? endpoint = freezed,Object? status = null,Object? lastSyncAt = freezed,Object? updatedAt = freezed,Object? configJson = freezed,}) {
  return _then(_IntegrationRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,endpoint: freezed == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,lastSyncAt: freezed == lastSyncAt ? _self.lastSyncAt : lastSyncAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,configJson: freezed == configJson ? _self._configJson : configJson // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
