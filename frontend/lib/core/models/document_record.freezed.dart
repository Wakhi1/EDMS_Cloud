// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DocumentRecord {

 int get id;@JsonKey(name: 'record_no') String get recordNo; String get title; String get status; String get classification;@JsonKey(name: 'member_number') String? get memberNumber;@JsonKey(name: 'member_name') String? get memberName;@JsonKey(name: 'created_at') String? get createdAt;@JsonKey(name: 'updated_at') String? get updatedAt;@JsonKey(name: 'document_type') String? get documentType; String? get department;@JsonKey(name: 'folder_path') String? get folderPath;@JsonKey(name: 'current_version_no') int? get currentVersionNo;@JsonKey(name: 'owner_name') String? get ownerName;
/// Create a copy of DocumentRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentRecordCopyWith<DocumentRecord> get copyWith => _$DocumentRecordCopyWithImpl<DocumentRecord>(this as DocumentRecord, _$identity);

  /// Serializes this DocumentRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.recordNo, recordNo) || other.recordNo == recordNo)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.classification, classification) || other.classification == classification)&&(identical(other.memberNumber, memberNumber) || other.memberNumber == memberNumber)&&(identical(other.memberName, memberName) || other.memberName == memberName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.documentType, documentType) || other.documentType == documentType)&&(identical(other.department, department) || other.department == department)&&(identical(other.folderPath, folderPath) || other.folderPath == folderPath)&&(identical(other.currentVersionNo, currentVersionNo) || other.currentVersionNo == currentVersionNo)&&(identical(other.ownerName, ownerName) || other.ownerName == ownerName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,recordNo,title,status,classification,memberNumber,memberName,createdAt,updatedAt,documentType,department,folderPath,currentVersionNo,ownerName);

@override
String toString() {
  return 'DocumentRecord(id: $id, recordNo: $recordNo, title: $title, status: $status, classification: $classification, memberNumber: $memberNumber, memberName: $memberName, createdAt: $createdAt, updatedAt: $updatedAt, documentType: $documentType, department: $department, folderPath: $folderPath, currentVersionNo: $currentVersionNo, ownerName: $ownerName)';
}


}

/// @nodoc
abstract mixin class $DocumentRecordCopyWith<$Res>  {
  factory $DocumentRecordCopyWith(DocumentRecord value, $Res Function(DocumentRecord) _then) = _$DocumentRecordCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'record_no') String recordNo, String title, String status, String classification,@JsonKey(name: 'member_number') String? memberNumber,@JsonKey(name: 'member_name') String? memberName,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'updated_at') String? updatedAt,@JsonKey(name: 'document_type') String? documentType, String? department,@JsonKey(name: 'folder_path') String? folderPath,@JsonKey(name: 'current_version_no') int? currentVersionNo,@JsonKey(name: 'owner_name') String? ownerName
});




}
/// @nodoc
class _$DocumentRecordCopyWithImpl<$Res>
    implements $DocumentRecordCopyWith<$Res> {
  _$DocumentRecordCopyWithImpl(this._self, this._then);

  final DocumentRecord _self;
  final $Res Function(DocumentRecord) _then;

/// Create a copy of DocumentRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? recordNo = null,Object? title = null,Object? status = null,Object? classification = null,Object? memberNumber = freezed,Object? memberName = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? documentType = freezed,Object? department = freezed,Object? folderPath = freezed,Object? currentVersionNo = freezed,Object? ownerName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,recordNo: null == recordNo ? _self.recordNo : recordNo // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,classification: null == classification ? _self.classification : classification // ignore: cast_nullable_to_non_nullable
as String,memberNumber: freezed == memberNumber ? _self.memberNumber : memberNumber // ignore: cast_nullable_to_non_nullable
as String?,memberName: freezed == memberName ? _self.memberName : memberName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,documentType: freezed == documentType ? _self.documentType : documentType // ignore: cast_nullable_to_non_nullable
as String?,department: freezed == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String?,folderPath: freezed == folderPath ? _self.folderPath : folderPath // ignore: cast_nullable_to_non_nullable
as String?,currentVersionNo: freezed == currentVersionNo ? _self.currentVersionNo : currentVersionNo // ignore: cast_nullable_to_non_nullable
as int?,ownerName: freezed == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentRecord].
extension DocumentRecordPatterns on DocumentRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentRecord value)  $default,){
final _that = this;
switch (_that) {
case _DocumentRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentRecord value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'record_no')  String recordNo,  String title,  String status,  String classification, @JsonKey(name: 'member_number')  String? memberNumber, @JsonKey(name: 'member_name')  String? memberName, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt, @JsonKey(name: 'document_type')  String? documentType,  String? department, @JsonKey(name: 'folder_path')  String? folderPath, @JsonKey(name: 'current_version_no')  int? currentVersionNo, @JsonKey(name: 'owner_name')  String? ownerName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentRecord() when $default != null:
return $default(_that.id,_that.recordNo,_that.title,_that.status,_that.classification,_that.memberNumber,_that.memberName,_that.createdAt,_that.updatedAt,_that.documentType,_that.department,_that.folderPath,_that.currentVersionNo,_that.ownerName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'record_no')  String recordNo,  String title,  String status,  String classification, @JsonKey(name: 'member_number')  String? memberNumber, @JsonKey(name: 'member_name')  String? memberName, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt, @JsonKey(name: 'document_type')  String? documentType,  String? department, @JsonKey(name: 'folder_path')  String? folderPath, @JsonKey(name: 'current_version_no')  int? currentVersionNo, @JsonKey(name: 'owner_name')  String? ownerName)  $default,) {final _that = this;
switch (_that) {
case _DocumentRecord():
return $default(_that.id,_that.recordNo,_that.title,_that.status,_that.classification,_that.memberNumber,_that.memberName,_that.createdAt,_that.updatedAt,_that.documentType,_that.department,_that.folderPath,_that.currentVersionNo,_that.ownerName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'record_no')  String recordNo,  String title,  String status,  String classification, @JsonKey(name: 'member_number')  String? memberNumber, @JsonKey(name: 'member_name')  String? memberName, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt, @JsonKey(name: 'document_type')  String? documentType,  String? department, @JsonKey(name: 'folder_path')  String? folderPath, @JsonKey(name: 'current_version_no')  int? currentVersionNo, @JsonKey(name: 'owner_name')  String? ownerName)?  $default,) {final _that = this;
switch (_that) {
case _DocumentRecord() when $default != null:
return $default(_that.id,_that.recordNo,_that.title,_that.status,_that.classification,_that.memberNumber,_that.memberName,_that.createdAt,_that.updatedAt,_that.documentType,_that.department,_that.folderPath,_that.currentVersionNo,_that.ownerName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentRecord implements DocumentRecord {
  const _DocumentRecord({required this.id, @JsonKey(name: 'record_no') required this.recordNo, required this.title, required this.status, required this.classification, @JsonKey(name: 'member_number') this.memberNumber, @JsonKey(name: 'member_name') this.memberName, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'document_type') this.documentType, this.department, @JsonKey(name: 'folder_path') this.folderPath, @JsonKey(name: 'current_version_no') this.currentVersionNo, @JsonKey(name: 'owner_name') this.ownerName});
  factory _DocumentRecord.fromJson(Map<String, dynamic> json) => _$DocumentRecordFromJson(json);

@override final  int id;
@override@JsonKey(name: 'record_no') final  String recordNo;
@override final  String title;
@override final  String status;
@override final  String classification;
@override@JsonKey(name: 'member_number') final  String? memberNumber;
@override@JsonKey(name: 'member_name') final  String? memberName;
@override@JsonKey(name: 'created_at') final  String? createdAt;
@override@JsonKey(name: 'updated_at') final  String? updatedAt;
@override@JsonKey(name: 'document_type') final  String? documentType;
@override final  String? department;
@override@JsonKey(name: 'folder_path') final  String? folderPath;
@override@JsonKey(name: 'current_version_no') final  int? currentVersionNo;
@override@JsonKey(name: 'owner_name') final  String? ownerName;

/// Create a copy of DocumentRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentRecordCopyWith<_DocumentRecord> get copyWith => __$DocumentRecordCopyWithImpl<_DocumentRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.recordNo, recordNo) || other.recordNo == recordNo)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.classification, classification) || other.classification == classification)&&(identical(other.memberNumber, memberNumber) || other.memberNumber == memberNumber)&&(identical(other.memberName, memberName) || other.memberName == memberName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.documentType, documentType) || other.documentType == documentType)&&(identical(other.department, department) || other.department == department)&&(identical(other.folderPath, folderPath) || other.folderPath == folderPath)&&(identical(other.currentVersionNo, currentVersionNo) || other.currentVersionNo == currentVersionNo)&&(identical(other.ownerName, ownerName) || other.ownerName == ownerName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,recordNo,title,status,classification,memberNumber,memberName,createdAt,updatedAt,documentType,department,folderPath,currentVersionNo,ownerName);

@override
String toString() {
  return 'DocumentRecord(id: $id, recordNo: $recordNo, title: $title, status: $status, classification: $classification, memberNumber: $memberNumber, memberName: $memberName, createdAt: $createdAt, updatedAt: $updatedAt, documentType: $documentType, department: $department, folderPath: $folderPath, currentVersionNo: $currentVersionNo, ownerName: $ownerName)';
}


}

/// @nodoc
abstract mixin class _$DocumentRecordCopyWith<$Res> implements $DocumentRecordCopyWith<$Res> {
  factory _$DocumentRecordCopyWith(_DocumentRecord value, $Res Function(_DocumentRecord) _then) = __$DocumentRecordCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'record_no') String recordNo, String title, String status, String classification,@JsonKey(name: 'member_number') String? memberNumber,@JsonKey(name: 'member_name') String? memberName,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'updated_at') String? updatedAt,@JsonKey(name: 'document_type') String? documentType, String? department,@JsonKey(name: 'folder_path') String? folderPath,@JsonKey(name: 'current_version_no') int? currentVersionNo,@JsonKey(name: 'owner_name') String? ownerName
});




}
/// @nodoc
class __$DocumentRecordCopyWithImpl<$Res>
    implements _$DocumentRecordCopyWith<$Res> {
  __$DocumentRecordCopyWithImpl(this._self, this._then);

  final _DocumentRecord _self;
  final $Res Function(_DocumentRecord) _then;

/// Create a copy of DocumentRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? recordNo = null,Object? title = null,Object? status = null,Object? classification = null,Object? memberNumber = freezed,Object? memberName = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? documentType = freezed,Object? department = freezed,Object? folderPath = freezed,Object? currentVersionNo = freezed,Object? ownerName = freezed,}) {
  return _then(_DocumentRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,recordNo: null == recordNo ? _self.recordNo : recordNo // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,classification: null == classification ? _self.classification : classification // ignore: cast_nullable_to_non_nullable
as String,memberNumber: freezed == memberNumber ? _self.memberNumber : memberNumber // ignore: cast_nullable_to_non_nullable
as String?,memberName: freezed == memberName ? _self.memberName : memberName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,documentType: freezed == documentType ? _self.documentType : documentType // ignore: cast_nullable_to_non_nullable
as String?,department: freezed == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String?,folderPath: freezed == folderPath ? _self.folderPath : folderPath // ignore: cast_nullable_to_non_nullable
as String?,currentVersionNo: freezed == currentVersionNo ? _self.currentVersionNo : currentVersionNo // ignore: cast_nullable_to_non_nullable
as int?,ownerName: freezed == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
