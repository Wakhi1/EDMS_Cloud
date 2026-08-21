import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/branding/branding_provider.dart';
import '../../../core/license/license_gate_provider.dart';
import '../../../core/models/company_branding.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/company_logo_box.dart';
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
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // Defense-in-depth beyond the router's own gate (core/router/app_router.dart):
    // that gate already keeps a not-yet-licensed deployment off /login
    // entirely, but its check runs once at cold app start and is cached
    // for the rest of the session. Re-verifying here means a license
    // revoked centrally while this tab has been sitting idle on /login
    // (or the user navigates back to it later in the same session,
    // without a full page reload) still gets caught — every real visit to
    // this screen asks docsecure-platform-provider again, not just app boot.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(licenseGateControllerProvider.notifier).recheck();
    });
  }

  @override
  Widget build(BuildContext context) {
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

class _HeroPanel extends ConsumerWidget {
  const _HeroPanel({required this.tokens});

  final PspfTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final branding = ref.watch(companyBrandingProvider).valueOrNull ?? CompanyBranding.fallback;
    return Container(
      color: tokens.surf2,
      padding: const EdgeInsets.fromLTRB(46, 42, 46, 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CompanyLogoBox(),
          const SizedBox(height: 22),
          Text(
            'KINGDOM OF ESWATINI',
            style: textTheme.labelMedium?.copyWith(letterSpacing: 0.22, color: tokens.ink3),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 320,
            child: Text(branding.name, style: textTheme.displaySmall),
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
