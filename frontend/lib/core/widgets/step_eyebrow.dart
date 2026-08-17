import 'package:flutter/material.dart';

import '../theme/pspf_tokens.dart';

/// The small uppercase "Sign in" / section-eyebrow label used throughout
/// the login flow and panel headers.
class StepEyebrow extends StatelessWidget {
  const StepEyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 0.18, color: context.tokens.ink3),
    );
  }
}
