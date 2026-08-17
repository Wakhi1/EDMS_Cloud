import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A generic label/value line chart — sibling to [LabelValueBarChart] with
/// the exact same `List<(String,double)>` contract, for report cards that
/// are genuinely time-series (a trend reads better as a line than as bars).
class LabelValueLineChart extends StatelessWidget {
  const LabelValueLineChart({super.key, required this.points, required this.color});

  final List<(String label, double value)> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxY = points.map((p) => p.$2).fold<double>(0, (a, b) => a > b ? a : b);
    return LineChart(
      LineChartData(
        minY: 0,
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
                  child: Text(points[i].$1, style: const TextStyle(fontSize: 9)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].$2)],
            isCurved: false,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}
