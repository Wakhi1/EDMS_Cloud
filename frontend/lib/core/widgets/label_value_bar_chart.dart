import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A generic label/value bar chart, generalized from
/// dashboard_screen.dart's private `_BarChart` (which stays CountItem-typed
/// and untouched there) so Reports' four sections — three CountItem-backed,
/// one ClaimTurnaroundPoint-backed — can share one fl_chart widget via a
/// trivial `.map()` at each call site instead of duplicating chart code.
class LabelValueBarChart extends StatelessWidget {
  const LabelValueBarChart({super.key, required this.points, required this.color});

  final List<(String label, double value)> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxY = points.map((p) => p.$2).fold<double>(0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(points[i].$1.replaceAll('_', ' '), style: const TextStyle(fontSize: 9)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(x: i, barRods: [BarChartRodData(toY: points[i].$2, color: color, width: 22)]),
        ],
      ),
    );
  }
}
