/// Second-factor methods offered at login. The backend doesn't expose which
/// methods a user has actually enrolled ahead of time (login only returns
/// `{mfaRequired:true, mfaToken}`) — see core/auth/auth_state.dart for how
/// the method-choice screen handles that.
enum MfaMethod { totp, sms, email, backupCode }

extension MfaMethodLabel on MfaMethod {
  String get label => switch (this) {
        MfaMethod.totp => 'Authenticator app',
        MfaMethod.sms => 'SMS one-time code',
        MfaMethod.email => 'Email one-time code',
        MfaMethod.backupCode => 'Backup recovery code',
      };
}
