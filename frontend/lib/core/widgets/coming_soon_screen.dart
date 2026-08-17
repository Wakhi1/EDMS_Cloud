import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/pspf_tokens.dart';

/// Placeholder for every module not yet built in Phase 1, so navigation
/// never dead-ends on a 404. Real screens replace these one module at a
/// time in later phases.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsDuotone.hourglassMedium, size: 40, color: tokens.ink3),
          const SizedBox(height: 12),
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Coming in a later phase.', style: textTheme.bodySmall?.copyWith(color: tokens.ink2)),
        ],
      ),
    );
  }
}
