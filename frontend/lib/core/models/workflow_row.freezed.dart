// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workflow_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkflowStepRow {

 int get id;@JsonKey(name: 'workflow_id') int get workflowId;@JsonKey(name: 'step_order') int get stepOrder;@JsonKey(name: 'step_name') String get stepName;@JsonKey(name: 'role_id') int get roleId;@JsonKey(name: 'role_name') String? get roleName;@JsonKey(name: 'sla_days') int? get slaDays;@JsonKey(name: 'escalation_role_id') int? get escalationRoleId;@JsonKey(name: 'escalation_role_name') String? get escalationRoleName;@JsonKey(name: 'sub_workflow_id') int? get subWorkflowId;@JsonKey(name: 'sub_workflow_name') String? get subWorkflowName;
/// Create a copy of WorkflowStepRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowStepRowCopyWith<WorkflowStepRow> get copyWith => _$WorkflowStepRowCopyWithImpl<WorkflowStepRow>(this as WorkflowStepRow, _$identity);

  /// Serializes this WorkflowStepRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowStepRow&&(identical(other.id, id) || other.id == id)&&(identical(other.workflowId, workflowId) || other.workflowId == workflowId)&&(identical(other.stepOrder, stepOrder) || other.stepOrder == stepOrder)&&(identical(other.stepName, stepName) || other.stepName == stepName)&&(identical(other.roleId, roleId) || other.roleId == roleId)&&(identical(other.roleName, roleName) || other.roleName == roleName)&&(identical(other.slaDays, slaDays) || other.slaDays == slaDays)&&(identical(other.escalationRoleId, escalationRoleId) || other.escalationRoleId == escalationRoleId)&&(identical(other.escalationRoleName, escalationRoleName) || other.escalationRoleName == escalationRoleName)&&(identical(other.subWorkflowId, subWorkflowId) || other.subWorkflowId == subWorkflowId)&&(identical(other.subWorkflowName, subWorkflowName) || other.subWorkflowName == subWorkflowName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workflowId,stepOrder,stepName,roleId,roleName,slaDays,escalationRoleId,escalationRoleName,subWorkflowId,subWorkflowName);

@override
String toString() {
  return 'WorkflowStepRow(id: $id, workflowId: $workflowId, stepOrder: $stepOrder, stepName: $stepName, roleId: $roleId, roleName: $roleName, slaDays: $slaDays, escalationRoleId: $escalationRoleId, escalationRoleName: $escalationRoleName, subWorkflowId: $subWorkflowId, subWorkflowName: $subWorkflowName)';
}


}

/// @nodoc
abstract mixin class $WorkflowStepRowCopyWith<$Res>  {
  factory $WorkflowStepRowCopyWith(WorkflowStepRow value, $Res Function(WorkflowStepRow) _then) = _$WorkflowStepRowCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'workflow_id') int workflowId,@JsonKey(name: 'step_order') int stepOrder,@JsonKey(name: 'step_name') String stepName,@JsonKey(name: 'role_id') int roleId,@JsonKey(name: 'role_name') String? roleName,@JsonKey(name: 'sla_days') int? slaDays,@JsonKey(name: 'escalation_role_id') int? escalationRoleId,@JsonKey(name: 'escalation_role_name') String? escalationRoleName,@JsonKey(name: 'sub_workflow_id') int? subWorkflowId,@JsonKey(name: 'sub_workflow_name') String? subWorkflowName
});




}
/// @nodoc
class _$WorkflowStepRowCopyWithImpl<$Res>
    implements $WorkflowStepRowCopyWith<$Res> {
  _$WorkflowStepRowCopyWithImpl(this._self, this._then);

  final WorkflowStepRow _self;
  final $Res Function(WorkflowStepRow) _then;

/// Create a copy of WorkflowStepRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workflowId = null,Object? stepOrder = null,Object? stepName = null,Object? roleId = null,Object? roleName = freezed,Object? slaDays = freezed,Object? escalationRoleId = freezed,Object? escalationRoleName = freezed,Object? subWorkflowId = freezed,Object? subWorkflowName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,workflowId: null == workflowId ? _self.workflowId : workflowId // ignore: cast_nullable_to_non_nullable
as int,stepOrder: null == stepOrder ? _self.stepOrder : stepOrder // ignore: cast_nullable_to_non_nullable
as int,stepName: null == stepName ? _self.stepName : stepName // ignore: cast_nullable_to_non_nullable
as String,roleId: null == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as int,roleName: freezed == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as String?,slaDays: freezed == slaDays ? _self.slaDays : slaDays // ignore: cast_nullable_to_non_nullable
as int?,escalationRoleId: freezed == escalationRoleId ? _self.escalationRoleId : escalationRoleId // ignore: cast_nullable_to_non_nullable
as int?,escalationRoleName: freezed == escalationRoleName ? _self.escalationRoleName : escalationRoleName // ignore: cast_nullable_to_non_nullable
as String?,subWorkflowId: freezed == subWorkflowId ? _self.subWorkflowId : subWorkflowId // ignore: cast_nullable_to_non_nullable
as int?,subWorkflowName: freezed == subWorkflowName ? _self.subWorkflowName : subWorkflowName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkflowStepRow].
extension WorkflowStepRowPatterns on WorkflowStepRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkflowStepRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkflowStepRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkflowStepRow value)  $default,){
final _that = this;
switch (_that) {
case _WorkflowStepRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkflowStepRow value)?  $default,){
final _that = this;
switch (_that) {
case _WorkflowStepRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'workflow_id')  int workflowId, @JsonKey(name: 'step_order')  int stepOrder, @JsonKey(name: 'step_name')  String stepName, @JsonKey(name: 'role_id')  int roleId, @JsonKey(name: 'role_name')  String? roleName, @JsonKey(name: 'sla_days')  int? slaDays, @JsonKey(name: 'escalation_role_id')  int? escalationRoleId, @JsonKey(name: 'escalation_role_name')  String? escalationRoleName, @JsonKey(name: 'sub_workflow_id')  int? subWorkflowId, @JsonKey(name: 'sub_workflow_name')  String? subWorkflowName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkflowStepRow() when $default != null:
return $default(_that.id,_that.workflowId,_that.stepOrder,_that.stepName,_that.roleId,_that.roleName,_that.slaDays,_that.escalationRoleId,_that.escalationRoleName,_that.subWorkflowId,_that.subWorkflowName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'workflow_id')  int workflowId, @JsonKey(name: 'step_order')  int stepOrder, @JsonKey(name: 'step_name')  String stepName, @JsonKey(name: 'role_id')  int roleId, @JsonKey(name: 'role_name')  String? roleName, @JsonKey(name: 'sla_days')  int? slaDays, @JsonKey(name: 'escalation_role_id')  int? escalationRoleId, @JsonKey(name: 'escalation_role_name')  String? escalationRoleName, @JsonKey(name: 'sub_workflow_id')  int? subWorkflowId, @JsonKey(name: 'sub_workflow_name')  String? subWorkflowName)  $default,) {final _that = this;
switch (_that) {
case _WorkflowStepRow():
return $default(_that.id,_that.workflowId,_that.stepOrder,_that.stepName,_that.roleId,_that.roleName,_that.slaDays,_that.escalationRoleId,_that.escalationRoleName,_that.subWorkflowId,_that.subWorkflowName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'workflow_id')  int workflowId, @JsonKey(name: 'step_order')  int stepOrder, @JsonKey(name: 'step_name')  String stepName, @JsonKey(name: 'role_id')  int roleId, @JsonKey(name: 'role_name')  String? roleName, @JsonKey(name: 'sla_days')  int? slaDays, @JsonKey(name: 'escalation_role_id')  int? escalationRoleId, @JsonKey(name: 'escalation_role_name')  String? escalationRoleName, @JsonKey(name: 'sub_workflow_id')  int? subWorkflowId, @JsonKey(name: 'sub_workflow_name')  String? subWorkflowName)?  $default,) {final _that = this;
switch (_that) {
case _WorkflowStepRow() when $default != null:
return $default(_that.id,_that.workflowId,_that.stepOrder,_that.stepName,_that.roleId,_that.roleName,_that.slaDays,_that.escalationRoleId,_that.escalationRoleName,_that.subWorkflowId,_that.subWorkflowName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkflowStepRow implements WorkflowStepRow {
  const _WorkflowStepRow({required this.id, @JsonKey(name: 'workflow_id') required this.workflowId, @JsonKey(name: 'step_order') required this.stepOrder, @JsonKey(name: 'step_name') required this.stepName, @JsonKey(name: 'role_id') required this.roleId, @JsonKey(name: 'role_name') this.roleName, @JsonKey(name: 'sla_days') this.slaDays, @JsonKey(name: 'escalation_role_id') this.escalationRoleId, @JsonKey(name: 'escalation_role_name') this.escalationRoleName, @JsonKey(name: 'sub_workflow_id') this.subWorkflowId, @JsonKey(name: 'sub_workflow_name') this.subWorkflowName});
  factory _WorkflowStepRow.fromJson(Map<String, dynamic> json) => _$WorkflowStepRowFromJson(json);

@override final  int id;
@override@JsonKey(name: 'workflow_id') final  int workflowId;
@override@JsonKey(name: 'step_order') final  int stepOrder;
@override@JsonKey(name: 'step_name') final  String stepName;
@override@JsonKey(name: 'role_id') final  int roleId;
@override@JsonKey(name: 'role_name') final  String? roleName;
@override@JsonKey(name: 'sla_days') final  int? slaDays;
@override@JsonKey(name: 'escalation_role_id') final  int? escalationRoleId;
@override@JsonKey(name: 'escalation_role_name') final  String? escalationRoleName;
@override@JsonKey(name: 'sub_workflow_id') final  int? subWorkflowId;
@override@JsonKey(name: 'sub_workflow_name') final  String? subWorkflowName;

/// Create a copy of WorkflowStepRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkflowStepRowCopyWith<_WorkflowStepRow> get copyWith => __$WorkflowStepRowCopyWithImpl<_WorkflowStepRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkflowStepRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkflowStepRow&&(identical(other.id, id) || other.id == id)&&(identical(other.workflowId, workflowId) || other.workflowId == workflowId)&&(identical(other.stepOrder, stepOrder) || other.stepOrder == stepOrder)&&(identical(other.stepName, stepName) || other.stepName == stepName)&&(identical(other.roleId, roleId) || other.roleId == roleId)&&(identical(other.roleName, roleName) || other.roleName == roleName)&&(identical(other.slaDays, slaDays) || other.slaDays == slaDays)&&(identical(other.escalationRoleId, escalationRoleId) || other.escalationRoleId == escalationRoleId)&&(identical(other.escalationRoleName, escalationRoleName) || other.escalationRoleName == escalationRoleName)&&(identical(other.subWorkflowId, subWorkflowId) || other.subWorkflowId == subWorkflowId)&&(identical(other.subWorkflowName, subWorkflowName) || other.subWorkflowName == subWorkflowName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workflowId,stepOrder,stepName,roleId,roleName,slaDays,escalationRoleId,escalationRoleName,subWorkflowId,subWorkflowName);

@override
String toString() {
  return 'WorkflowStepRow(id: $id, workflowId: $workflowId, stepOrder: $stepOrder, stepName: $stepName, roleId: $roleId, roleName: $roleName, slaDays: $slaDays, escalationRoleId: $escalationRoleId, escalationRoleName: $escalationRoleName, subWorkflowId: $subWorkflowId, subWorkflowName: $subWorkflowName)';
}


}

/// @nodoc
abstract mixin class _$WorkflowStepRowCopyWith<$Res> implements $WorkflowStepRowCopyWith<$Res> {
  factory _$WorkflowStepRowCopyWith(_WorkflowStepRow value, $Res Function(_WorkflowStepRow) _then) = __$WorkflowStepRowCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'workflow_id') int workflowId,@JsonKey(name: 'step_order') int stepOrder,@JsonKey(name: 'step_name') String stepName,@JsonKey(name: 'role_id') int roleId,@JsonKey(name: 'role_name') String? roleName,@JsonKey(name: 'sla_days') int? slaDays,@JsonKey(name: 'escalation_role_id') int? escalationRoleId,@JsonKey(name: 'escalation_role_name') String? escalationRoleName,@JsonKey(name: 'sub_workflow_id') int? subWorkflowId,@JsonKey(name: 'sub_workflow_name') String? subWorkflowName
});




}
/// @nodoc
class __$WorkflowStepRowCopyWithImpl<$Res>
    implements _$WorkflowStepRowCopyWith<$Res> {
  __$WorkflowStepRowCopyWithImpl(this._self, this._then);

  final _WorkflowStepRow _self;
  final $Res Function(_WorkflowStepRow) _then;

/// Create a copy of WorkflowStepRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workflowId = null,Object? stepOrder = null,Object? stepName = null,Object? roleId = null,Object? roleName = freezed,Object? slaDays = freezed,Object? escalationRoleId = freezed,Object? escalationRoleName = freezed,Object? subWorkflowId = freezed,Object? subWorkflowName = freezed,}) {
  return _then(_WorkflowStepRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,workflowId: null == workflowId ? _self.workflowId : workflowId // ignore: cast_nullable_to_non_nullable
as int,stepOrder: null == stepOrder ? _self.stepOrder : stepOrder // ignore: cast_nullable_to_non_nullable
as int,stepName: null == stepName ? _self.stepName : stepName // ignore: cast_nullable_to_non_nullable
as String,roleId: null == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as int,roleName: freezed == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as String?,slaDays: freezed == slaDays ? _self.slaDays : slaDays // ignore: cast_nullable_to_non_nullable
as int?,escalationRoleId: freezed == escalationRoleId ? _self.escalationRoleId : escalationRoleId // ignore: cast_nullable_to_non_nullable
as int?,escalationRoleName: freezed == escalationRoleName ? _self.escalationRoleName : escalationRoleName // ignore: cast_nullable_to_non_nullable
as String?,subWorkflowId: freezed == subWorkflowId ? _self.subWorkflowId : subWorkflowId // ignore: cast_nullable_to_non_nullable
as int?,subWorkflowName: freezed == subWorkflowName ? _self.subWorkflowName : subWorkflowName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$WorkflowRow {

 int get id; String get name;@JsonKey(name: 'trigger_doc_type_id') int? get triggerDocTypeId;@JsonKey(name: 'trigger_folder_id') int? get triggerFolderId;@JsonKey(name: 'is_active', fromJson: _boolFromInt) bool get isActive; List<WorkflowStepRow> get steps;
/// Create a copy of WorkflowRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowRowCopyWith<WorkflowRow> get copyWith => _$WorkflowRowCopyWithImpl<WorkflowRow>(this as WorkflowRow, _$identity);

  /// Serializes this WorkflowRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowRow&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.triggerDocTypeId, triggerDocTypeId) || other.triggerDocTypeId == triggerDocTypeId)&&(identical(other.triggerFolderId, triggerFolderId) || other.triggerFolderId == triggerFolderId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&const DeepCollectionEquality().equals(other.steps, steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,triggerDocTypeId,triggerFolderId,isActive,const DeepCollectionEquality().hash(steps));

@override
String toString() {
  return 'WorkflowRow(id: $id, name: $name, triggerDocTypeId: $triggerDocTypeId, triggerFolderId: $triggerFolderId, isActive: $isActive, steps: $steps)';
}


}

/// @nodoc
abstract mixin class $WorkflowRowCopyWith<$Res>  {
  factory $WorkflowRowCopyWith(WorkflowRow value, $Res Function(WorkflowRow) _then) = _$WorkflowRowCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'trigger_doc_type_id') int? triggerDocTypeId,@JsonKey(name: 'trigger_folder_id') int? triggerFolderId,@JsonKey(name: 'is_active', fromJson: _boolFromInt) bool isActive, List<WorkflowStepRow> steps
});




}
/// @nodoc
class _$WorkflowRowCopyWithImpl<$Res>
    implements $WorkflowRowCopyWith<$Res> {
  _$WorkflowRowCopyWithImpl(this._self, this._then);

  final WorkflowRow _self;
  final $Res Function(WorkflowRow) _then;

/// Create a copy of WorkflowRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? triggerDocTypeId = freezed,Object? triggerFolderId = freezed,Object? isActive = null,Object? steps = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,triggerDocTypeId: freezed == triggerDocTypeId ? _self.triggerDocTypeId : triggerDocTypeId // ignore: cast_nullable_to_non_nullable
as int?,triggerFolderId: freezed == triggerFolderId ? _self.triggerFolderId : triggerFolderId // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<WorkflowStepRow>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkflowRow].
extension WorkflowRowPatterns on WorkflowRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkflowRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkflowRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkflowRow value)  $default,){
final _that = this;
switch (_that) {
case _WorkflowRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkflowRow value)?  $default,){
final _that = this;
switch (_that) {
case _WorkflowRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'trigger_doc_type_id')  int? triggerDocTypeId, @JsonKey(name: 'trigger_folder_id')  int? triggerFolderId, @JsonKey(name: 'is_active', fromJson: _boolFromInt)  bool isActive,  List<WorkflowStepRow> steps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkflowRow() when $default != null:
return $default(_that.id,_that.name,_that.triggerDocTypeId,_that.triggerFolderId,_that.isActive,_that.steps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'trigger_doc_type_id')  int? triggerDocTypeId, @JsonKey(name: 'trigger_folder_id')  int? triggerFolderId, @JsonKey(name: 'is_active', fromJson: _boolFromInt)  bool isActive,  List<WorkflowStepRow> steps)  $default,) {final _that = this;
switch (_that) {
case _WorkflowRow():
return $default(_that.id,_that.name,_that.triggerDocTypeId,_that.triggerFolderId,_that.isActive,_that.steps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'trigger_doc_type_id')  int? triggerDocTypeId, @JsonKey(name: 'trigger_folder_id')  int? triggerFolderId, @JsonKey(name: 'is_active', fromJson: _boolFromInt)  bool isActive,  List<WorkflowStepRow> steps)?  $default,) {final _that = this;
switch (_that) {
case _WorkflowRow() when $default != null:
return $default(_that.id,_that.name,_that.triggerDocTypeId,_that.triggerFolderId,_that.isActive,_that.steps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkflowRow implements WorkflowRow {
  const _WorkflowRow({required this.id, required this.name, @JsonKey(name: 'trigger_doc_type_id') this.triggerDocTypeId, @JsonKey(name: 'trigger_folder_id') this.triggerFolderId, @JsonKey(name: 'is_active', fromJson: _boolFromInt) this.isActive = true, final  List<WorkflowStepRow> steps = const <WorkflowStepRow>[]}): _steps = steps;
  factory _WorkflowRow.fromJson(Map<String, dynamic> json) => _$WorkflowRowFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'trigger_doc_type_id') final  int? triggerDocTypeId;
@override@JsonKey(name: 'trigger_folder_id') final  int? triggerFolderId;
@override@JsonKey(name: 'is_active', fromJson: _boolFromInt) final  bool isActive;
 final  List<WorkflowStepRow> _steps;
@override@JsonKey() List<WorkflowStepRow> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}


/// Create a copy of WorkflowRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkflowRowCopyWith<_WorkflowRow> get copyWith => __$WorkflowRowCopyWithImpl<_WorkflowRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkflowRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkflowRow&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.triggerDocTypeId, triggerDocTypeId) || other.triggerDocTypeId == triggerDocTypeId)&&(identical(other.triggerFolderId, triggerFolderId) || other.triggerFolderId == triggerFolderId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&const DeepCollectionEquality().equals(other._steps, _steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,triggerDocTypeId,triggerFolderId,isActive,const DeepCollectionEquality().hash(_steps));

@override
String toString() {
  return 'WorkflowRow(id: $id, name: $name, triggerDocTypeId: $triggerDocTypeId, triggerFolderId: $triggerFolderId, isActive: $isActive, steps: $steps)';
}


}

/// @nodoc
abstract mixin class _$WorkflowRowCopyWith<$Res> implements $WorkflowRowCopyWith<$Res> {
  factory _$WorkflowRowCopyWith(_WorkflowRow value, $Res Function(_WorkflowRow) _then) = __$WorkflowRowCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'trigger_doc_type_id') int? triggerDocTypeId,@JsonKey(name: 'trigger_folder_id') int? triggerFolderId,@JsonKey(name: 'is_active', fromJson: _boolFromInt) bool isActive, List<WorkflowStepRow> steps
});




}
/// @nodoc
class __$WorkflowRowCopyWithImpl<$Res>
    implements _$WorkflowRowCopyWith<$Res> {
  __$WorkflowRowCopyWithImpl(this._self, this._then);

  final _WorkflowRow _self;
  final $Res Function(_WorkflowRow) _then;

/// Create a copy of WorkflowRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? triggerDocTypeId = freezed,Object? triggerFolderId = freezed,Object? isActive = null,Object? steps = null,}) {
  return _then(_WorkflowRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,triggerDocTypeId: freezed == triggerDocTypeId ? _self.triggerDocTypeId : triggerDocTypeId // ignore: cast_nullable_to_non_nullable
as int?,triggerFolderId: freezed == triggerFolderId ? _self.triggerFolderId : triggerFolderId // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<WorkflowStepRow>,
  ));
}


}

// dart format on
