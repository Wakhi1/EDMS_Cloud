import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/pspf_tokens.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.label, required this.value, this.sub, this.icon, this.onTap});

  final String label;
  final String value;
  final String? sub;
  final PhosphorIconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: tokens.surf,
          border: Border.all(color: tokens.line),
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 3, color: tokens.acc, margin: const EdgeInsets.only(bottom: 10)),
            Row(
              children: [
                if (icon != null) ...[Icon(icon, size: 16, color: tokens.accD), const SizedBox(width: 6)],
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: textTheme.displaySmall?.copyWith(fontSize: 30)),
            if (sub != null) Text(sub!, style: textTheme.bodySmall?.copyWith(color: tokens.ink2)),
          ],
        ),
      ),
    );
  }
}
