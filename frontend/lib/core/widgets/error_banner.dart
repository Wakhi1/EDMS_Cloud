import 'package:flutter/material.dart';

import '../theme/pspf_tokens.dart';

/// Inline error message shown within a form step (e.g. wrong password,
/// invalid MFA code) — distinct from [AppSnackbar], which is for
/// transient, non-blocking feedback.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: tokens.surf2,
        border: Border(left: BorderSide(color: tokens.bad, width: 3)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens.bad),
      ),
    );
  }
}
