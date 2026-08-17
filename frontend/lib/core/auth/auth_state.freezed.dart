// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LoginState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LoginState()';
}


}

/// @nodoc
class $LoginStateCopyWith<$Res>  {
$LoginStateCopyWith(LoginState _, $Res Function(LoginState) __);
}


/// Adds pattern-matching-related methods to [LoginState].
extension LoginStatePatterns on LoginState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LoginEnteringCredentials value)?  enteringCredentials,TResult Function( LoginChooseMfaMethod value)?  chooseMfaMethod,TResult Function( LoginEnteringMfaCode value)?  enteringMfaCode,TResult Function( LoginEnrollingTotp value)?  enrollingTotp,TResult Function( LoginDeviceTrust value)?  deviceTrust,TResult Function( LoginAuthenticated value)?  authenticated,TResult Function( LoginAccountLocked value)?  accountLocked,TResult Function( LoginResetPassword value)?  resetPassword,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LoginEnteringCredentials() when enteringCredentials != null:
return enteringCredentials(_that);case LoginChooseMfaMethod() when chooseMfaMethod != null:
return chooseMfaMethod(_that);case LoginEnteringMfaCode() when enteringMfaCode != null:
return enteringMfaCode(_that);case LoginEnrollingTotp() when enrollingTotp != null:
return enrollingTotp(_that);case LoginDeviceTrust() when deviceTrust != null:
return deviceTrust(_that);case LoginAuthenticated() when authenticated != null:
return authenticated(_that);case LoginAccountLocked() when accountLocked != null:
return accountLocked(_that);case LoginResetPassword() when resetPassword != null:
return resetPassword(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LoginEnteringCredentials value)  enteringCredentials,required TResult Function( LoginChooseMfaMethod value)  chooseMfaMethod,required TResult Function( LoginEnteringMfaCode value)  enteringMfaCode,required TResult Function( LoginEnrollingTotp value)  enrollingTotp,required TResult Function( LoginDeviceTrust value)  deviceTrust,required TResult Function( LoginAuthenticated value)  authenticated,required TResult Function( LoginAccountLocked value)  accountLocked,required TResult Function( LoginResetPassword value)  resetPassword,}){
final _that = this;
switch (_that) {
case LoginEnteringCredentials():
return enteringCredentials(_that);case LoginChooseMfaMethod():
return chooseMfaMethod(_that);case LoginEnteringMfaCode():
return enteringMfaCode(_that);case LoginEnrollingTotp():
return enrollingTotp(_that);case LoginDeviceTrust():
return deviceTrust(_that);case LoginAuthenticated():
return authenticated(_that);case LoginAccountLocked():
return accountLocked(_that);case LoginResetPassword():
return resetPassword(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LoginEnteringCredentials value)?  enteringCredentials,TResult? Function( LoginChooseMfaMethod value)?  chooseMfaMethod,TResult? Function( LoginEnteringMfaCode value)?  enteringMfaCode,TResult? Function( LoginEnrollingTotp value)?  enrollingTotp,TResult? Function( LoginDeviceTrust value)?  deviceTrust,TResult? Function( LoginAuthenticated value)?  authenticated,TResult? Function( LoginAccountLocked value)?  accountLocked,TResult? Function( LoginResetPassword value)?  resetPassword,}){
final _that = this;
switch (_that) {
case LoginEnteringCredentials() when enteringCredentials != null:
return enteringCredentials(_that);case LoginChooseMfaMethod() when chooseMfaMethod != null:
return chooseMfaMethod(_that);case LoginEnteringMfaCode() when enteringMfaCode != null:
return enteringMfaCode(_that);case LoginEnrollingTotp() when enrollingTotp != null:
return enrollingTotp(_that);case LoginDeviceTrust() when deviceTrust != null:
return deviceTrust(_that);case LoginAuthenticated() when authenticated != null:
return authenticated(_that);case LoginAccountLocked() when accountLocked != null:
return accountLocked(_that);case LoginResetPassword() when resetPassword != null:
return resetPassword(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( bool isSubmitting,  String? error)?  enteringCredentials,TResult Function( String mfaToken,  bool totpEnrolled,  bool hasPhoneNumber,  bool isSubmitting,  String? error)?  chooseMfaMethod,TResult Function( String mfaToken,  MfaMethod method,  bool isSubmitting,  String? error)?  enteringMfaCode,TResult Function( String mfaToken,  String qrDataUrl,  String base32Secret,  bool isSubmitting,  String? error)?  enrollingTotp,TResult Function( AppUser user,  MfaMethod method)?  deviceTrust,TResult Function( AppUser user)?  authenticated,TResult Function()?  accountLocked,TResult Function( bool sent,  bool isSubmitting,  String? error)?  resetPassword,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LoginEnteringCredentials() when enteringCredentials != null:
return enteringCredentials(_that.isSubmitting,_that.error);case LoginChooseMfaMethod() when chooseMfaMethod != null:
return chooseMfaMethod(_that.mfaToken,_that.totpEnrolled,_that.hasPhoneNumber,_that.isSubmitting,_that.error);case LoginEnteringMfaCode() when enteringMfaCode != null:
return enteringMfaCode(_that.mfaToken,_that.method,_that.isSubmitting,_that.error);case LoginEnrollingTotp() when enrollingTotp != null:
return enrollingTotp(_that.mfaToken,_that.qrDataUrl,_that.base32Secret,_that.isSubmitting,_that.error);case LoginDeviceTrust() when deviceTrust != null:
return deviceTrust(_that.user,_that.method);case LoginAuthenticated() when authenticated != null:
return authenticated(_that.user);case LoginAccountLocked() when accountLocked != null:
return accountLocked();case LoginResetPassword() when resetPassword != null:
return resetPassword(_that.sent,_that.isSubmitting,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( bool isSubmitting,  String? error)  enteringCredentials,required TResult Function( String mfaToken,  bool totpEnrolled,  bool hasPhoneNumber,  bool isSubmitting,  String? error)  chooseMfaMethod,required TResult Function( String mfaToken,  MfaMethod method,  bool isSubmitting,  String? error)  enteringMfaCode,required TResult Function( String mfaToken,  String qrDataUrl,  String base32Secret,  bool isSubmitting,  String? error)  enrollingTotp,required TResult Function( AppUser user,  MfaMethod method)  deviceTrust,required TResult Function( AppUser user)  authenticated,required TResult Function()  accountLocked,required TResult Function( bool sent,  bool isSubmitting,  String? error)  resetPassword,}) {final _that = this;
switch (_that) {
case LoginEnteringCredentials():
return enteringCredentials(_that.isSubmitting,_that.error);case LoginChooseMfaMethod():
return chooseMfaMethod(_that.mfaToken,_that.totpEnrolled,_that.hasPhoneNumber,_that.isSubmitting,_that.error);case LoginEnteringMfaCode():
return enteringMfaCode(_that.mfaToken,_that.method,_that.isSubmitting,_that.error);case LoginEnrollingTotp():
return enrollingTotp(_that.mfaToken,_that.qrDataUrl,_that.base32Secret,_that.isSubmitting,_that.error);case LoginDeviceTrust():
return deviceTrust(_that.user,_that.method);case LoginAuthenticated():
return authenticated(_that.user);case LoginAccountLocked():
return accountLocked();case LoginResetPassword():
return resetPassword(_that.sent,_that.isSubmitting,_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( bool isSubmitting,  String? error)?  enteringCredentials,TResult? Function( String mfaToken,  bool totpEnrolled,  bool hasPhoneNumber,  bool isSubmitting,  String? error)?  chooseMfaMethod,TResult? Function( String mfaToken,  MfaMethod method,  bool isSubmitting,  String? error)?  enteringMfaCode,TResult? Function( String mfaToken,  String qrDataUrl,  String base32Secret,  bool isSubmitting,  String? error)?  enrollingTotp,TResult? Function( AppUser user,  MfaMethod method)?  deviceTrust,TResult? Function( AppUser user)?  authenticated,TResult? Function()?  accountLocked,TResult? Function( bool sent,  bool isSubmitting,  String? error)?  resetPassword,}) {final _that = this;
switch (_that) {
case LoginEnteringCredentials() when enteringCredentials != null:
return enteringCredentials(_that.isSubmitting,_that.error);case LoginChooseMfaMethod() when chooseMfaMethod != null:
return chooseMfaMethod(_that.mfaToken,_that.totpEnrolled,_that.hasPhoneNumber,_that.isSubmitting,_that.error);case LoginEnteringMfaCode() when enteringMfaCode != null:
return enteringMfaCode(_that.mfaToken,_that.method,_that.isSubmitting,_that.error);case LoginEnrollingTotp() when enrollingTotp != null:
return enrollingTotp(_that.mfaToken,_that.qrDataUrl,_that.base32Secret,_that.isSubmitting,_that.error);case LoginDeviceTrust() when deviceTrust != null:
return deviceTrust(_that.user,_that.method);case LoginAuthenticated() when authenticated != null:
return authenticated(_that.user);case LoginAccountLocked() when accountLocked != null:
return accountLocked();case LoginResetPassword() when resetPassword != null:
return resetPassword(_that.sent,_that.isSubmitting,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class LoginEnteringCredentials implements LoginState {
  const LoginEnteringCredentials({this.isSubmitting = false, this.error});
  

@JsonKey() final  bool isSubmitting;
 final  String? error;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginEnteringCredentialsCopyWith<LoginEnteringCredentials> get copyWith => _$LoginEnteringCredentialsCopyWithImpl<LoginEnteringCredentials>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginEnteringCredentials&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,isSubmitting,error);

@override
String toString() {
  return 'LoginState.enteringCredentials(isSubmitting: $isSubmitting, error: $error)';
}


}

/// @nodoc
abstract mixin class $LoginEnteringCredentialsCopyWith<$Res> implements $LoginStateCopyWith<$Res> {
  factory $LoginEnteringCredentialsCopyWith(LoginEnteringCredentials value, $Res Function(LoginEnteringCredentials) _then) = _$LoginEnteringCredentialsCopyWithImpl;
@useResult
$Res call({
 bool isSubmitting, String? error
});




}
/// @nodoc
class _$LoginEnteringCredentialsCopyWithImpl<$Res>
    implements $LoginEnteringCredentialsCopyWith<$Res> {
  _$LoginEnteringCredentialsCopyWithImpl(this._self, this._then);

  final LoginEnteringCredentials _self;
  final $Res Function(LoginEnteringCredentials) _then;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? isSubmitting = null,Object? error = freezed,}) {
  return _then(LoginEnteringCredentials(
isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class LoginChooseMfaMethod implements LoginState {
  const LoginChooseMfaMethod({required this.mfaToken, this.totpEnrolled = false, this.hasPhoneNumber = false, this.isSubmitting = false, this.error});
  

 final  String mfaToken;
@JsonKey() final  bool totpEnrolled;
@JsonKey() final  bool hasPhoneNumber;
@JsonKey() final  bool isSubmitting;
 final  String? error;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginChooseMfaMethodCopyWith<LoginChooseMfaMethod> get copyWith => _$LoginChooseMfaMethodCopyWithImpl<LoginChooseMfaMethod>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginChooseMfaMethod&&(identical(other.mfaToken, mfaToken) || other.mfaToken == mfaToken)&&(identical(other.totpEnrolled, totpEnrolled) || other.totpEnrolled == totpEnrolled)&&(identical(other.hasPhoneNumber, hasPhoneNumber) || other.hasPhoneNumber == hasPhoneNumber)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,mfaToken,totpEnrolled,hasPhoneNumber,isSubmitting,error);

@override
String toString() {
  return 'LoginState.chooseMfaMethod(mfaToken: $mfaToken, totpEnrolled: $totpEnrolled, hasPhoneNumber: $hasPhoneNumber, isSubmitting: $isSubmitting, error: $error)';
}


}

/// @nodoc
abstract mixin class $LoginChooseMfaMethodCopyWith<$Res> implements $LoginStateCopyWith<$Res> {
  factory $LoginChooseMfaMethodCopyWith(LoginChooseMfaMethod value, $Res Function(LoginChooseMfaMethod) _then) = _$LoginChooseMfaMethodCopyWithImpl;
@useResult
$Res call({
 String mfaToken, bool totpEnrolled, bool hasPhoneNumber, bool isSubmitting, String? error
});




}
/// @nodoc
class _$LoginChooseMfaMethodCopyWithImpl<$Res>
    implements $LoginChooseMfaMethodCopyWith<$Res> {
  _$LoginChooseMfaMethodCopyWithImpl(this._self, this._then);

  final LoginChooseMfaMethod _self;
  final $Res Function(LoginChooseMfaMethod) _then;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mfaToken = null,Object? totpEnrolled = null,Object? hasPhoneNumber = null,Object? isSubmitting = null,Object? error = freezed,}) {
  return _then(LoginChooseMfaMethod(
mfaToken: null == mfaToken ? _self.mfaToken : mfaToken // ignore: cast_nullable_to_non_nullable
as String,totpEnrolled: null == totpEnrolled ? _self.totpEnrolled : totpEnrolled // ignore: cast_nullable_to_non_nullable
as bool,hasPhoneNumber: null == hasPhoneNumber ? _self.hasPhoneNumber : hasPhoneNumber // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class LoginEnteringMfaCode implements LoginState {
  const LoginEnteringMfaCode({required this.mfaToken, required this.method, this.isSubmitting = false, this.error});
  

 final  String mfaToken;
 final  MfaMethod method;
@JsonKey() final  bool isSubmitting;
 final  String? error;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginEnteringMfaCodeCopyWith<LoginEnteringMfaCode> get copyWith => _$LoginEnteringMfaCodeCopyWithImpl<LoginEnteringMfaCode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginEnteringMfaCode&&(identical(other.mfaToken, mfaToken) || other.mfaToken == mfaToken)&&(identical(other.method, method) || other.method == method)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,mfaToken,method,isSubmitting,error);

@override
String toString() {
  return 'LoginState.enteringMfaCode(mfaToken: $mfaToken, method: $method, isSubmitting: $isSubmitting, error: $error)';
}


}

/// @nodoc
abstract mixin class $LoginEnteringMfaCodeCopyWith<$Res> implements $LoginStateCopyWith<$Res> {
  factory $LoginEnteringMfaCodeCopyWith(LoginEnteringMfaCode value, $Res Function(LoginEnteringMfaCode) _then) = _$LoginEnteringMfaCodeCopyWithImpl;
@useResult
$Res call({
 String mfaToken, MfaMethod method, bool isSubmitting, String? error
});




}
/// @nodoc
class _$LoginEnteringMfaCodeCopyWithImpl<$Res>
    implements $LoginEnteringMfaCodeCopyWith<$Res> {
  _$LoginEnteringMfaCodeCopyWithImpl(this._self, this._then);

  final LoginEnteringMfaCode _self;
  final $Res Function(LoginEnteringMfaCode) _then;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mfaToken = null,Object? method = null,Object? isSubmitting = null,Object? error = freezed,}) {
  return _then(LoginEnteringMfaCode(
mfaToken: null == mfaToken ? _self.mfaToken : mfaToken // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as MfaMethod,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class LoginEnrollingTotp implements LoginState {
  const LoginEnrollingTotp({required this.mfaToken, required this.qrDataUrl, required this.base32Secret, this.isSubmitting = false, this.error});
  

 final  String mfaToken;
 final  String qrDataUrl;
 final  String base32Secret;
@JsonKey() final  bool isSubmitting;
 final  String? error;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginEnrollingTotpCopyWith<LoginEnrollingTotp> get copyWith => _$LoginEnrollingTotpCopyWithImpl<LoginEnrollingTotp>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginEnrollingTotp&&(identical(other.mfaToken, mfaToken) || other.mfaToken == mfaToken)&&(identical(other.qrDataUrl, qrDataUrl) || other.qrDataUrl == qrDataUrl)&&(identical(other.base32Secret, base32Secret) || other.base32Secret == base32Secret)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,mfaToken,qrDataUrl,base32Secret,isSubmitting,error);

@override
String toString() {
  return 'LoginState.enrollingTotp(mfaToken: $mfaToken, qrDataUrl: $qrDataUrl, base32Secret: $base32Secret, isSubmitting: $isSubmitting, error: $error)';
}


}

/// @nodoc
abstract mixin class $LoginEnrollingTotpCopyWith<$Res> implements $LoginStateCopyWith<$Res> {
  factory $LoginEnrollingTotpCopyWith(LoginEnrollingTotp value, $Res Function(LoginEnrollingTotp) _then) = _$LoginEnrollingTotpCopyWithImpl;
@useResult
$Res call({
 String mfaToken, String qrDataUrl, String base32Secret, bool isSubmitting, String? error
});




}
/// @nodoc
class _$LoginEnrollingTotpCopyWithImpl<$Res>
    implements $LoginEnrollingTotpCopyWith<$Res> {
  _$LoginEnrollingTotpCopyWithImpl(this._self, this._then);

  final LoginEnrollingTotp _self;
  final $Res Function(LoginEnrollingTotp) _then;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mfaToken = null,Object? qrDataUrl = null,Object? base32Secret = null,Object? isSubmitting = null,Object? error = freezed,}) {
  return _then(LoginEnrollingTotp(
mfaToken: null == mfaToken ? _self.mfaToken : mfaToken // ignore: cast_nullable_to_non_nullable
as String,qrDataUrl: null == qrDataUrl ? _self.qrDataUrl : qrDataUrl // ignore: cast_nullable_to_non_nullable
as String,base32Secret: null == base32Secret ? _self.base32Secret : base32Secret // ignore: cast_nullable_to_non_nullable
as String,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class LoginDeviceTrust implements LoginState {
  const LoginDeviceTrust({required this.user, required this.method});
  

 final  AppUser user;
 final  MfaMethod method;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginDeviceTrustCopyWith<LoginDeviceTrust> get copyWith => _$LoginDeviceTrustCopyWithImpl<LoginDeviceTrust>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginDeviceTrust&&(identical(other.user, user) || other.user == user)&&(identical(other.method, method) || other.method == method));
}


@override
int get hashCode => Object.hash(runtimeType,user,method);

@override
String toString() {
  return 'LoginState.deviceTrust(user: $user, method: $method)';
}


}

/// @nodoc
abstract mixin class $LoginDeviceTrustCopyWith<$Res> implements $LoginStateCopyWith<$Res> {
  factory $LoginDeviceTrustCopyWith(LoginDeviceTrust value, $Res Function(LoginDeviceTrust) _then) = _$LoginDeviceTrustCopyWithImpl;
@useResult
$Res call({
 AppUser user, MfaMethod method
});


$AppUserCopyWith<$Res> get user;

}
/// @nodoc
class _$LoginDeviceTrustCopyWithImpl<$Res>
    implements $LoginDeviceTrustCopyWith<$Res> {
  _$LoginDeviceTrustCopyWithImpl(this._self, this._then);

  final LoginDeviceTrust _self;
  final $Res Function(LoginDeviceTrust) _then;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,Object? method = null,}) {
  return _then(LoginDeviceTrust(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AppUser,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as MfaMethod,
  ));
}

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppUserCopyWith<$Res> get user {
  
  return $AppUserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

/// @nodoc


class LoginAuthenticated implements LoginState {
  const LoginAuthenticated({required this.user});
  

 final  AppUser user;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginAuthenticatedCopyWith<LoginAuthenticated> get copyWith => _$LoginAuthenticatedCopyWithImpl<LoginAuthenticated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginAuthenticated&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'LoginState.authenticated(user: $user)';
}


}

/// @nodoc
abstract mixin class $LoginAuthenticatedCopyWith<$Res> implements $LoginStateCopyWith<$Res> {
  factory $LoginAuthenticatedCopyWith(LoginAuthenticated value, $Res Function(LoginAuthenticated) _then) = _$LoginAuthenticatedCopyWithImpl;
@useResult
$Res call({
 AppUser user
});


$AppUserCopyWith<$Res> get user;

}
/// @nodoc
class _$LoginAuthenticatedCopyWithImpl<$Res>
    implements $LoginAuthenticatedCopyWith<$Res> {
  _$LoginAuthenticatedCopyWithImpl(this._self, this._then);

  final LoginAuthenticated _self;
  final $Res Function(LoginAuthenticated) _then;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(LoginAuthenticated(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AppUser,
  ));
}

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppUserCopyWith<$Res> get user {
  
  return $AppUserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

/// @nodoc


class LoginAccountLocked implements LoginState {
  const LoginAccountLocked();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginAccountLocked);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LoginState.accountLocked()';
}


}




/// @nodoc


class LoginResetPassword implements LoginState {
  const LoginResetPassword({this.sent = false, this.isSubmitting = false, this.error});
  

@JsonKey() final  bool sent;
@JsonKey() final  bool isSubmitting;
 final  String? error;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginResetPasswordCopyWith<LoginResetPassword> get copyWith => _$LoginResetPasswordCopyWithImpl<LoginResetPassword>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginResetPassword&&(identical(other.sent, sent) || other.sent == sent)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,sent,isSubmitting,error);

@override
String toString() {
  return 'LoginState.resetPassword(sent: $sent, isSubmitting: $isSubmitting, error: $error)';
}


}

/// @nodoc
abstract mixin class $LoginResetPasswordCopyWith<$Res> implements $LoginStateCopyWith<$Res> {
  factory $LoginResetPasswordCopyWith(LoginResetPassword value, $Res Function(LoginResetPassword) _then) = _$LoginResetPasswordCopyWithImpl;
@useResult
$Res call({
 bool sent, bool isSubmitting, String? error
});




}
/// @nodoc
class _$LoginResetPasswordCopyWithImpl<$Res>
    implements $LoginResetPasswordCopyWith<$Res> {
  _$LoginResetPasswordCopyWithImpl(this._self, this._then);

  final LoginResetPassword _self;
  final $Res Function(LoginResetPassword) _then;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sent = null,Object? isSubmitting = null,Object? error = freezed,}) {
  return _then(LoginResetPassword(
sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
