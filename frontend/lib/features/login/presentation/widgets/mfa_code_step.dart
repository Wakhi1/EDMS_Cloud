import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/auth/mfa_method.dart';
import '../../../../core/theme/pspf_tokens.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/step_eyebrow.dart';

class MfaCodeStep extends ConsumerStatefulWidget {
  const MfaCodeStep({super.key, required this.state});

  final LoginEnteringMfaCode state;

  @override
  ConsumerState<MfaCodeStep> createState() => _MfaCodeStepState();
}

class _MfaCodeStepState extends ConsumerState<MfaCodeStep> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    ref.read(authControllerProvider.notifier).verifyMfa(code);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final state = widget.state;
    final isCodeSentMethod = state.method == MfaMethod.sms || state.method == MfaMethod.email;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const StepEyebrow('Sign in'),
        const SizedBox(height: 4),
        Text(state.method.label, style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          isCodeSentMethod
              ? 'Enter the code we just sent you.'
              : state.method == MfaMethod.totp
                  ? 'Enter the 6-digit code from your authenticator app.'
                  : 'Enter one of your unused backup recovery codes.',
          style: textTheme.bodyMedium?.copyWith(color: tokens.ink2),
        ),
        const SizedBox(height: 16),
        if (state.error != null) ...[
          ErrorBanner(state.error!),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _codeController,
          enabled: !state.isSubmitting,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.w600),
          keyboardType: state.method == MfaMethod.backupCode ? TextInputType.text : TextInputType.number,
          decoration: const InputDecoration(hintText: '——————'),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.isSubmitting ? null : _submit,
            child: state.isSubmitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('VERIFY & SIGN IN'),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: state.isSubmitting ? null : () => ref.read(authControllerProvider.notifier).backToMethodChoice(),
              child: const Text('Choose another method'),
            ),
            if (isCodeSentMethod)
              TextButton(
                onPressed: state.isSubmitting ? null : () => ref.read(authControllerProvider.notifier).sendMfaChallenge(),
                child: const Text('Resend code'),
              ),
          ],
        ),
      ],
    );
  }
}
