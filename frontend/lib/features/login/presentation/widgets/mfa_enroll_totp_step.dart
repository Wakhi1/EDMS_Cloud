import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/pspf_tokens.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/step_eyebrow.dart';

/// Shown instead of [MfaCodeStep] when the signing-in user picks
/// "Authenticator app" but has never enrolled one — first-time setup
/// (scan QR, confirm) happens right here, and confirming also completes
/// the login in one step.
class MfaEnrollTotpStep extends ConsumerStatefulWidget {
  const MfaEnrollTotpStep({super.key, required this.state});

  final LoginEnrollingTotp state;

  @override
  ConsumerState<MfaEnrollTotpStep> createState() => _MfaEnrollTotpStepState();
}

class _MfaEnrollTotpStepState extends ConsumerState<MfaEnrollTotpStep> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    ref.read(authControllerProvider.notifier).confirmEnrollTotp(code);
  }

  void _copyKey() {
    Clipboard.setData(ClipboardData(text: widget.state.base32Secret));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Key copied.')));
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
        Text('Set up authenticator app', style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'First time — scan this QR code in your authenticator app, then enter '
          'the 6-digit code it shows to finish signing in.',
          style: textTheme.bodyMedium?.copyWith(color: tokens.ink2),
        ),
        const SizedBox(height: 16),
        if (state.error != null) ...[
          ErrorBanner(state.error!),
          const SizedBox(height: 12),
        ],
        Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Image.memory(
              base64Decode(state.qrDataUrl.split(',').last),
              width: 170,
              height: 170,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text("Can't scan? Enter this key manually:", style: TextStyle(fontSize: 12, color: tokens.ink2)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(border: Border.all(color: tokens.line2), color: tokens.surf2),
                child: Text(
                  state.base32Secret,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(onPressed: _copyKey, icon: const Icon(Icons.copy, size: 17), tooltip: 'Copy key'),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codeController,
          enabled: !state.isSubmitting,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.w600),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '6-digit code'),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.isSubmitting ? null : _submit,
            child: state.isSubmitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('CONFIRM & SIGN IN'),
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: state.isSubmitting ? null : () => ref.read(authControllerProvider.notifier).backToMethodChoice(),
          child: const Text('Choose another method'),
        ),
      ],
    );
  }
}
