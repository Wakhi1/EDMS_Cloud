import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/auth/mfa_method.dart';
import '../../../../core/theme/pspf_tokens.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/step_eyebrow.dart';

class MfaMethodStep extends ConsumerWidget {
  const MfaMethodStep({super.key, required this.state});

  final LoginChooseMfaMethod state;

  static const _allMethods = [
    (MfaMethod.totp, 'Code from an authenticator app'),
    (MfaMethod.sms, 'One-time code sent by SMS'),
    (MfaMethod.email, 'One-time code sent by email'),
    (MfaMethod.backupCode, 'Use a saved backup recovery code'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    // SMS is only offered to users with a valid phone number on file —
    // otherwise the challenge/sms/send call would just fail after the tap.
    final methods = [
      for (final entry in _allMethods)
        if (entry.$1 != MfaMethod.sms || state.hasPhoneNumber) entry,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const StepEyebrow('Sign in'),
        const SizedBox(height: 4),
        Text('Second factor', style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Multi-factor authentication is mandatory for this role.',
          style: textTheme.bodyMedium?.copyWith(color: tokens.ink2),
        ),
        const SizedBox(height: 16),
        if (state.error != null) ...[
          ErrorBanner(state.error!),
          const SizedBox(height: 12),
        ],
        for (final (method, sub) in methods) ...[
          _MethodButton(
            label: method.label,
            sub: sub,
            onTap: state.isSubmitting
                ? null
                : () => ref.read(authControllerProvider.notifier).chooseMfaMethod(method),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => ref.read(authControllerProvider.notifier).backToCredentials(),
          child: const Text('Back'),
        ),
      ],
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({required this.label, required this.sub, required this.onTap});

  final String label;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.titleSmall),
          Text(sub, style: textTheme.bodySmall?.copyWith(color: tokens.ink2)),
        ],
      ),
    );
  }
}
