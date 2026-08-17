import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/pspf_tokens.dart';

/// The design mockup's Sharing & Links module (internal shares + secure
/// external links with password/watermark/expiry) has no backend support
/// at all — confirmed by a full grep of the Node backend: no route, no
/// service, no database table. Per the user's explicit decision this ships
/// as a static placeholder only; building real functionality here would
/// require new backend work that's out of scope for this phase.
class SharingPlaceholderScreen extends StatelessWidget {
  const SharingPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsDuotone.shareNetwork, size: 40, color: tokens.ink3),
              const SizedBox(height: 12),
              Text('Sharing & Links', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Not yet available. Internal record sharing and secure external links '
                'require backend work that has not been built yet.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: tokens.ink2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
