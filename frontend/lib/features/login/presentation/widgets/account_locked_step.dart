import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/theme/pspf_tokens.dart';

/// Reached automatically when POST /api/auth/login returns 423 (account
/// locked after too many failed attempts).
class AccountLockedStep extends ConsumerWidget {
  const AccountLockedStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline, color: tokens.bad, size: 30),
            const SizedBox(width: 10),
            Text('Account locked', style: textTheme.headlineSmall),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Too many failed sign-in attempts were recorded on this account. It unlocks '
          'automatically after a short period, or immediately once ICT verifies your identity.',
          style: textTheme.bodyMedium?.copyWith(color: tokens.ink2),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: tokens.surf2,
            border: Border(left: BorderSide(color: tokens.bad, width: 3)),
          ),
          child: Text(
            'If these attempts were not yours, report them to ICT at once.',
            style: textTheme.bodySmall?.copyWith(color: tokens.ink2),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => ref.read(authControllerProvider.notifier).backToCredentials(),
          child: const Text('Back to sign in'),
        ),
      ],
    );
  }
}
