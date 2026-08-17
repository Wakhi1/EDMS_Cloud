import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/auth/mfa_method.dart';
import '../../../../core/theme/pspf_tokens.dart';
import '../../../../core/widgets/step_eyebrow.dart';

class DeviceTrustStep extends ConsumerStatefulWidget {
  const DeviceTrustStep({super.key, required this.state});

  final LoginDeviceTrust state;

  @override
  ConsumerState<DeviceTrustStep> createState() => _DeviceTrustStepState();
}

class _DeviceTrustStepState extends ConsumerState<DeviceTrustStep> {
  bool _trust = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const StepEyebrow('Sign in'),
        const SizedBox(height: 4),
        Text('Register this device', style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Second factor accepted via ${widget.state.method.label}.',
          style: textTheme.bodyMedium?.copyWith(color: tokens.ink2),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _trust,
          onChanged: (v) => setState(() => _trust = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            'Trust this device — skip the second-factor method screen here next time. '
            'Never select this on a shared registry workstation.',
            style: textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => ref.read(authControllerProvider.notifier).finishLogin(
                  trustDevice: _trust,
                  method: widget.state.method,
                ),
            child: const Text('ENTER THE SYSTEM'),
          ),
        ),
      ],
    );
  }
}
