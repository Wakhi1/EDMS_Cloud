import 'package:flutter/material.dart';

import '../theme/pspf_tokens.dart';

/// A horizontal label + proportional-bar list — reads far better than
/// [LabelValueBarChart]'s vertical bars once there are more than a
/// handful of categories or the labels are longer than a word or two
/// (long document-type names, audit action names, user names): vertical
/// bars in a narrow grid cell force tiny rotated/overlapping axis labels,
/// while a sorted list with inline bars stays legible at any length.
class LabelValueBarList extends StatelessWidget {
  const LabelValueBarList({super.key, required this.points, required this.color, this.valueSuffix = ''});

  final List<(String label, double value)> points;
  final Color color;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final maxValue = points.map((p) => p.$2).fold<double>(0, (a, b) => a > b ? a : b);

    return ListView.separated(
      itemCount: points.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final (label, value) = points[i];
        final fraction = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0, 1).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                Text('${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}$valueSuffix', style: TextStyle(fontSize: 11, color: tokens.ink2)),
              ],
            ),
            const SizedBox(height: 3),
            ClipRRect(
              child: LinearProgressIndicator(value: fraction, minHeight: 5, backgroundColor: tokens.surf2, color: color),
            ),
          ],
        );
      },
    );
  }
}
