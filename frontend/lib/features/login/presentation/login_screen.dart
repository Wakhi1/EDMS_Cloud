import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/theme/pspf_tokens.dart';
import 'widgets/account_locked_step.dart';
import 'widgets/credentials_step.dart';
import 'widgets/device_trust_step.dart';
import 'widgets/mfa_code_step.dart';
import 'widgets/mfa_enroll_totp_step.dart';
import 'widgets/mfa_method_step.dart';
import 'widgets/reset_password_step.dart';

/// Hosts the entire login state machine (see core/auth/auth_state.dart) as
/// a single screen whose body swaps between step widgets. Matches the
/// mockup's split layout: a hero panel on wide screens + a form panel that
/// always renders full-width on narrow screens.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final tokens = context.tokens;
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      backgroundColor: tokens.paper,
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (state) {
          return Row(
            children: [
              if (wide) Expanded(flex: 5, child: _HeroPanel(tokens: tokens)),
              Expanded(
                flex: 4,
                child: Container(
                  color: tokens.paper,
                  padding: EdgeInsets.symmetric(horizontal: wide ? 34 : 20, vertical: wide ? 42 : 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: SingleChildScrollView(child: _stepFor(state)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stepFor(LoginState state) {
    return switch (state) {
      LoginEnteringCredentials() => CredentialsStep(state: state),
      LoginChooseMfaMethod() => MfaMethodStep(state: state),
      LoginEnteringMfaCode() => MfaCodeStep(state: state),
      LoginEnrollingTotp() => MfaEnrollTotpStep(state: state),
      LoginDeviceTrust() => DeviceTrustStep(state: state),
      LoginAccountLocked() => const AccountLockedStep(),
      LoginResetPassword() => ResetPasswordStep(state: state),
      LoginAuthenticated() => const SizedBox.shrink(), // router redirects away immediately
    };
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.tokens});

  final PspfTokens tokens;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: tokens.surf2,
      padding: const EdgeInsets.fromLTRB(46, 42, 46, 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            color: tokens.acc,
            alignment: Alignment.center,
            child: const Text('P', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 22),
          Text(
            'KINGDOM OF ESWATINI',
            style: textTheme.labelMedium?.copyWith(letterSpacing: 0.22, color: tokens.ink3),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 320,
            child: Text('Public Service Pensions Fund', style: textTheme.displaySmall),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 380,
            child: Text(
              'Electronic Document & Records Management System. Capture, retrieval, '
              'approval and disposal of member, contribution and payout records.',
              style: textTheme.bodyLarge?.copyWith(color: tokens.ink2),
            ),
          ),
          const Spacer(),
          Text(
            'Authorised users only. All access is logged under the Records Act.',
            style: textTheme.bodySmall?.copyWith(color: tokens.ink3),
          ),
        ],
      ),
    );
  }
}
