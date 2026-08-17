import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/pspf_tokens.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/step_eyebrow.dart';

class ResetPasswordStep extends ConsumerStatefulWidget {
  const ResetPasswordStep({super.key, required this.state});

  final LoginResetPassword state;

  @override
  ConsumerState<ResetPasswordStep> createState() => _ResetPasswordStepState();
}

class _ResetPasswordStepState extends ConsumerState<ResetPasswordStep> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final state = widget.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const StepEyebrow('Sign in'),
        const SizedBox(height: 4),
        Text('Reset password', style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'A single-use link is sent to your official PSPF email address.',
          style: textTheme.bodyMedium?.copyWith(color: tokens.ink2),
        ),
        const SizedBox(height: 16),
        if (state.error != null) ...[
          ErrorBanner(state.error!),
          const SizedBox(height: 12),
        ],
        if (state.sent)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            decoration: BoxDecoration(
              color: tokens.surf2,
              border: Border(left: BorderSide(color: tokens.ok, width: 3)),
            ),
            child: Text(
              'If that address matches an account, a reset link has been sent. '
              'It expires in 20 minutes and can be used once.',
              style: textTheme.bodySmall?.copyWith(color: tokens.ink2),
            ),
          )
        else ...[
          Text('EMAIL ADDRESS', style: textTheme.labelMedium),
          const SizedBox(height: 4),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !state.isSubmitting,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isSubmitting
                  ? null
                  : () => ref.read(authControllerProvider.notifier).sendPasswordReset(_emailController.text.trim()),
              child: state.isSubmitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('SEND RESET LINK'),
            ),
          ),
        ],
        const SizedBox(height: 14),
        TextButton(
          onPressed: () => ref.read(authControllerProvider.notifier).backToCredentials(),
          child: const Text('Back to sign in'),
        ),
      ],
    );
  }
}
