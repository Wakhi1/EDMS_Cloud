import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/pspf_tokens.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/step_eyebrow.dart';

class CredentialsStep extends ConsumerStatefulWidget {
  const CredentialsStep({super.key, required this.state});

  final LoginEnteringCredentials state;

  @override
  ConsumerState<CredentialsStep> createState() => _CredentialsStepState();
}

class _CredentialsStepState extends ConsumerState<CredentialsStep> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _viaAd = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          viaAd: _viaAd,
        );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final submitting = widget.state.isSubmitting;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const StepEyebrow('Sign in'),
          const SizedBox(height: 4),
          Text('Staff credentials', style: textTheme.headlineSmall),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Local account')),
              ButtonSegment(value: true, label: Text('Active Directory')),
            ],
            selected: {_viaAd},
            onSelectionChanged: submitting ? null : (v) => setState(() => _viaAd = v.first),
          ),
          const SizedBox(height: 16),
          if (widget.state.error != null) ...[
            ErrorBanner(widget.state.error!),
            const SizedBox(height: 14),
          ],
          Text('EMAIL', style: textTheme.labelMedium),
          const SizedBox(height: 4),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !submitting,
            autofillHints: const [AutofillHints.username],
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your PSPF email address.' : null,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          Text('PASSWORD', style: textTheme.labelMedium),
          const SizedBox(height: 4),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            enabled: !submitting,
            autofillHints: const [AutofillHints.password],
            validator: (v) => (v == null || v.isEmpty) ? 'Enter your password.' : null,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitting ? null : _submit,
              child: submitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('CONTINUE'),
            ),
          ),
          const SizedBox(height: 14),
          if (!_viaAd)
            TextButton(
              onPressed: submitting ? null : () => ref.read(authControllerProvider.notifier).goToResetPassword(),
              child: const Text('Forgot password'),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: tokens.surf2,
              border: Border(left: BorderSide(color: tokens.warn, width: 3)),
            ),
            child: Text(
              'Access is restricted to authorised PSPF staff and ministry liaison officers. '
              'Sign-in attempts, IP address and device are recorded.',
              style: textTheme.bodySmall?.copyWith(color: tokens.ink2),
            ),
          ),
        ],
      ),
    );
  }
}
