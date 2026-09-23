import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/models/count_item.dart';
import '../../../core/models/dashboard_summary.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/utils/format_bytes.dart';
import '../providers/dashboard_providers.dart';

/// Compact, role-shaped overview. Everything headline comes from one call
/// (GET /api/dashboard/summary); sections the role can't see are simply
/// left out rather than rendered as "not available" placeholders.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _gap = 14.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final user = ref.watch(currentUserProvider);
    final summary = ref.watch(dashboardSummaryProvider);
    final trend = ref.watch(dashboardCapturedOverTimeProvider);
    final data = summary.valueOrNull;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1000;

    void refresh() {
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(dashboardApprovalsProvider);
      ref.invalidate(dashboardOverdueRetentionProvider);
      ref.invalidate(dashboardCapturedOverTimeProvider);
    }

    Widget row(List<(int, Widget)> cells) {
      final visible = cells.where((c) => c.$2 is! SizedBox).toList();
      if (visible.isEmpty) return const SizedBox.shrink();
      if (!wide) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < visible.length; i++) ...[if (i > 0) const SizedBox(height: _gap), visible[i].$2],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < visible.length; i++) ...[if (i > 0) const SizedBox(width: _gap), Expanded(flex: visible[i].$1, child: visible[i].$2)],
        ],
      );
    }

    final hasApprovals = !ref.watch(dashboardApprovalsProvider).hasError;
    final hasTrend = trend.hasValue && (trend.valueOrNull?.isNotEmpty ?? false);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text('Welcome back, ${user?.fullName ?? ''} · ${_today()}', style: TextStyle(fontSize: 12.5, color: tokens.ink2)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                visualDensity: VisualDensity.compact,
                icon: Icon(PhosphorIconsRegular.arrowClockwise, size: 18, color: tokens.ink2),
                onPressed: refresh,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _AlertStrip(),
          if (summary.hasError)
            _Panel(
              title: 'Overview unavailable',
              child: Text('${summary.error}', style: TextStyle(color: tokens.ink2, fontSize: 12.5)),
            )
          else ...[
            _StatStrip(summary: data, loading: summary.isLoading),
            const SizedBox(height: _gap),
            row([
              (5, data?.documents != null ? _StatusPanel(docs: data!.documents!) : const SizedBox.shrink()),
              (7, hasTrend ? _TrendPanel(points: trend.value!) : const SizedBox.shrink()),
            ]),
            const SizedBox(height: _gap),
            row([
              (4, data?.storage != null ? _StoragePanel(storage: data!.storage!) : const SizedBox.shrink()),
              (4, data?.documents != null ? _TypesPanel(types: data!.documents!.byType) : const SizedBox.shrink()),
              (4, hasApprovals ? const _ApprovalsPanel() : const SizedBox.shrink()),
            ]),
          ],
        ],
      ),
    );
  }

  static String _today() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.actionLabel, this.onAction, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surf,
        border: Border.all(color: tokens.line),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    children: [
                      if (subtitle != null)
                        TextSpan(
                          text: '  $subtitle',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400, color: tokens.ink3),
                        ),
                    ],
                  ),
                ),
              ),
              if (actionLabel != null)
                InkWell(
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel!,
                          style: TextStyle(fontSize: 11.5, color: tokens.accD, fontWeight: FontWeight.w600),
                        ),
                        Icon(PhosphorIconsRegular.caretRight, size: 12, color: tokens.accD),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Only renders when there is something to act on — no "0 overdue" noise.
class _AlertStrip extends ConsumerWidget {
  const _AlertStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final approvals = ref.watch(dashboardApprovalsProvider).valueOrNull?.length ?? 0;
    final overdue = ref.watch(dashboardOverdueRetentionProvider).valueOrNull ?? 0;
    final alerts = [
      if (approvals > 0) (PhosphorIconsRegular.sealCheck, '$approvals awaiting your approval', tokens.warn, '/approvals'),
      if (overdue > 0) (PhosphorIconsRegular.clockCountdown, '$overdue record${overdue == 1 ? '' : 's'} overdue for disposal', tokens.bad, '/retention'),
    ];
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          for (final (icon, text, color, route) in alerts)
            InkWell(
              onTap: () => context.go(route),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  border: Border(left: BorderSide(color: color, width: 3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: color),
                    const SizedBox(width: 7),
                    Text(
                      text,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: tokens.ink),
                    ),
                    const SizedBox(width: 6),
                    Icon(PhosphorIconsRegular.arrowRight, size: 13, color: tokens.ink2),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One bordered strip of headline figures, split into equal cells.
class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.summary, required this.loading});

  final DashboardSummary? summary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final docs = summary?.documents;
    final folders = summary?.folders;
    final storage = summary?.storage;

    final stats = <_Stat>[
      if (docs != null || loading) ...[
        _Stat(
          PhosphorIconsRegular.files,
          'Documents',
          docs?.live,
          docs == null ? null : '${docs.createdThisMonth} new this month',
          route: RoutePaths.repository,
        ),
        _Stat(PhosphorIconsRegular.stack, 'Files', docs?.fileCount, docs == null ? null : formatBytes(docs.currentBytes)),
        _Stat(
          PhosphorIconsRegular.bookOpenText,
          'Pages',
          docs?.pageCount,
          docs == null ? null : (docs.uncountedFiles > 0 ? '${docs.uncountedFiles} not countable' : 'current versions'),
          prefix: docs?.pagesEstimated == true ? '~' : '',
        ),
      ],
      if (folders != null) _Stat(PhosphorIconsRegular.folders, 'Folders', folders.total, '${folders.empty} empty', route: RoutePaths.repository),
      if (storage != null) _Stat(PhosphorIconsRegular.hardDrives, 'Storage', null, '${storage.objectCount} objects', text: formatBytes(storage.usedBytes)),
      if (docs != null) _Stat(PhosphorIconsRegular.user, 'My records', docs.mine, '${docs.statusCount('pending_approval')} in approval'),
    ];
    if (stats.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = constraints.maxWidth >= 900 ? stats.length : (constraints.maxWidth >= 560 ? 3 : 2);
        final cellWidth = constraints.maxWidth / perRow;
        return Container(
          decoration: BoxDecoration(
            color: tokens.surf,
            border: Border.all(color: tokens.line),
          ),
          child: Wrap(
            children: [
              for (var i = 0; i < stats.length; i++)
                SizedBox(
                  width: cellWidth - (i % perRow == perRow - 1 ? 2 : 0),
                  child: _StatCell(stat: stats[i], divider: i % perRow != perRow - 1),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat {
  const _Stat(this.icon, this.label, this.value, this.sub, {this.route, this.prefix = '', this.text});

  final IconData icon;
  final String label;
  final int? value;
  final String? sub;
  final String? route;
  final String prefix;
  final String? text;
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stat, required this.divider});

  final _Stat stat;
  final bool divider;

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(n >= 10000000 ? 0 : 1)}M';
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(n >= 100000 ? 0 : 1)}k';
    final s = n.toString();
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final value = stat.text ?? (stat.value == null ? '—' : '${stat.prefix}${_compact(stat.value!)}');
    return InkWell(
      onTap: stat.route == null ? null : () => context.go(stat.route!),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          border: divider ? Border(right: BorderSide(color: tokens.line)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(stat.icon, size: 14, color: tokens.accD),
                const SizedBox(width: 6),
                Text(
                  stat.label.toUpperCase(),
                  style: TextStyle(fontSize: 10.5, letterSpacing: 0.6, fontWeight: FontWeight.w600, color: tokens.ink2),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tokens.ink, height: 1.1),
            ),
            const SizedBox(height: 2),
            Text(
              stat.sub ?? ' ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: tokens.ink3),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panels
// ---------------------------------------------------------------------------

const _statusLabels = {
  'draft': 'Draft',
  'pending_approval': 'Pending approval',
  'approved': 'Approved',
  'rejected': 'Rejected',
  'declared_final': 'Declared final',
  'archived': 'Recycle bin',
  'disposed': 'Disposed',
};

Color _statusColor(PspfTokens t, String status) => switch (status) {
  'draft' => t.acc2,
  'pending_approval' => t.warn,
  'approved' => t.ok,
  'rejected' => t.bad,
  'declared_final' => t.acc,
  'archived' => t.ink3,
  _ => t.line2,
};

/// Usage as a percentage, without rounding a non-empty location down to "0.0%".
String _percent(double fraction) {
  if (fraction > 0 && fraction < 0.001) return '<0.1%';
  return '${(fraction * 100).toStringAsFixed(1)}%';
}

/// Donut of documents by status with an interactive legend.
class _StatusPanel extends StatefulWidget {
  const _StatusPanel({required this.docs});

  final DocumentStats docs;

  @override
  State<_StatusPanel> createState() => _StatusPanelState();
}

class _StatusPanelState extends State<_StatusPanel> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final counts = widget.docs.byStatus;
    final total = counts.fold<int>(0, (s, c) => s + c.total);
    final nonZero = counts.where((c) => c.total > 0).toList();
    final focus = _touched != null && _touched! < nonZero.length ? nonZero[_touched!] : null;

    return _Panel(
      title: 'Documents by status',
      actionLabel: 'Repository',
      onAction: () => context.go(RoutePaths.repository),
      child: total == 0
          ? const _Empty('No documents yet.')
          : Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 50,
                          startDegreeOffset: -90,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              final index = response?.touchedSection?.touchedSectionIndex;
                              final next = event.isInterestedForInteractions && index != null && index >= 0 ? index : null;
                              if (next != _touched) setState(() => _touched = next);
                            },
                          ),
                          sections: [
                            for (var i = 0; i < nonZero.length; i++)
                              PieChartSectionData(
                                value: nonZero[i].total.toDouble(),
                                color: _statusColor(tokens, nonZero[i].label),
                                radius: _touched == i ? 22 : 17,
                                showTitle: false,
                              ),
                          ],
                        ),
                        duration: const Duration(milliseconds: 250),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${focus?.total ?? total}',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tokens.ink),
                          ),
                          Text(
                            focus == null ? 'total' : (_statusLabels[focus.label] ?? focus.label),
                            style: TextStyle(fontSize: 10.5, color: tokens.ink2),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final c in counts)
                        _LegendRow(
                          color: _statusColor(tokens, c.label),
                          label: _statusLabels[c.label] ?? c.label,
                          value: c.total,
                          percent: total == 0 ? 0 : c.total / total,
                          highlighted: focus?.label == c.label,
                          muted: c.total == 0,
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, required this.value, required this.percent, this.highlighted = false, this.muted = false});

  final Color color;
  final String label;
  final int value;
  final double percent;
  final bool highlighted;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ink = muted ? tokens.ink3 : tokens.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      color: highlighted ? tokens.surf2 : null,
      child: Row(
        children: [
          Container(width: 8, height: 8, color: muted ? tokens.line2 : color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: ink),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ink),
          ),
          SizedBox(
            width: 42,
            child: Text(
              '${(percent * 100).round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: tokens.ink3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Smooth area chart of records captured per period.
class _TrendPanel extends StatelessWidget {
  const _TrendPanel({required this.points});

  final List<CountItem> points;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final maxY = points.fold<int>(0, (m, p) => p.total > m ? p.total : m).toDouble();
    // Four whole-number gridlines on a round step (0/3/6/9/12, not 0/4/7/11/14).
    final step = maxY <= 0 ? 1.0 : (maxY * 1.1 / 4).ceilToDouble();
    final top = step * 4;
    final labelEvery = (points.length / 6).ceil().clamp(1, 1000);
    final total = points.fold<int>(0, (s, p) => s + p.total);

    return _Panel(
      title: 'Capture trend',
      subtitle: '$total records in ${points.length} periods',
      child: SizedBox(
        height: 170,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: top,
            minX: 0,
            maxX: (points.length - 1).toDouble().clamp(1, double.infinity),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: step,
              getDrawingHorizontalLine: (_) => FlLine(color: tokens.line, strokeWidth: 1, dashArray: const [3, 4]),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: step,
                  getTitlesWidget: (value, meta) => Text(value.round().toString(), style: TextStyle(fontSize: 10, color: tokens.ink3)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    if (value != i || i < 0 || i >= points.length || i % labelEvery != 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(points[i].label, style: TextStyle(fontSize: 10, color: tokens.ink3)),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => tokens.ink,
                tooltipBorderRadius: BorderRadius.zero,
                getTooltipItems: (spots) => [
                  for (final s in spots)
                    LineTooltipItem(
                      '${points[s.x.round()].label}\n',
                      TextStyle(fontSize: 10.5, color: tokens.surf2),
                      children: [
                        TextSpan(
                          text: '${s.y.round()} records',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tokens.surf),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].total.toDouble())],
                isCurved: true,
                curveSmoothness: 0.3,
                preventCurveOverShooting: true,
                color: tokens.acc,
                barWidth: 2.2,
                dotData: FlDotData(show: points.length <= 12),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [tokens.acc.withValues(alpha: 0.28), tokens.acc.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }
}

class _StoragePanel extends StatelessWidget {
  const _StoragePanel({required this.storage});

  final StorageStats storage;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return _Panel(
      title: 'Storage by location',
      subtitle: formatBytes(storage.usedBytes),
      child: storage.locations.isEmpty
          ? const _Empty('No storage locations configured.')
          : Column(
              children: [
                for (final l in storage.locations) ...[
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: l.status == 'connected' ? tokens.ok : (l.status == 'error' ? tokens.bad : tokens.ink3),
                        ),
                      ),
                      const SizedBox(width: 7),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 170),
                        child: Text(
                          l.name,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (l.active) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          color: tokens.accT,
                          child: Text(
                            'ACTIVE',
                            style: TextStyle(fontSize: 9, letterSpacing: 0.4, color: tokens.accD, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          l.capacityBytes > 0 ? _percent(l.usedFraction) : formatBytes(l.usedBytes),
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: tokens.ink2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _Meter(
                    fraction: l.capacityBytes > 0 ? l.usedFraction : 0,
                    color: l.usedFraction > 0.9 ? tokens.bad : (l.usedFraction > 0.75 ? tokens.warn : tokens.acc),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.capacityBytes > 0
                          ? '${formatBytes(l.usedBytes)} of ${formatBytes(l.capacityBytes)} · ${l.objectCount} objects'
                          : '${l.objectCount} objects · capacity not set',
                      style: TextStyle(fontSize: 10.5, color: tokens.ink3),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _TypesPanel extends StatelessWidget {
  const _TypesPanel({required this.types});

  final List<CountItem> types;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final max = types.fold<int>(0, (m, c) => c.total > m ? c.total : m);
    return _Panel(
      title: 'Top document types',
      child: types.isEmpty
          ? const _Empty('No documents yet.')
          : Column(
              children: [
                for (final t in types.take(6)) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(t.label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                      Text('${t.total}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _Meter(fraction: max == 0 ? 0 : t.total / max, color: tokens.acc),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _ApprovalsPanel extends ConsumerWidget {
  const _ApprovalsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final approvals = ref.watch(dashboardApprovalsProvider);
    if (approvals.hasError) return const SizedBox.shrink();
    final items = approvals.valueOrNull;

    return _Panel(
      title: 'Awaiting my approval',
      actionLabel: 'Inbox',
      onAction: () => context.go('/approvals'),
      child: items == null
          ? const LinearProgressIndicator(minHeight: 2)
          : items.isEmpty
          ? const _Empty('Inbox clear — nothing waiting on you.', icon: PhosphorIconsRegular.checkCircle)
          : Column(
              children: [
                for (final a in items.take(5))
                  InkWell(
                    onTap: () => context.go('/approvals'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: tokens.line)),
                      ),
                      child: Row(
                        children: [
                          Icon(PhosphorIconsRegular.fileText, size: 15, color: tokens.ink3),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${a.recordNo} · ${a.stepName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: tokens.ink2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (items.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('+${items.length - 5} more', style: TextStyle(fontSize: 11, color: tokens.ink3)),
                  ),
              ],
            ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      height: 6,
      child: Stack(
        children: [
          Container(color: tokens.surf2),
          FractionallySizedBox(
            widthFactor: fraction.clamp(0, 1).toDouble(),
            child: Container(color: color),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.message, {this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon ?? PhosphorIconsRegular.tray, size: 16, color: tokens.ink3),
          const SizedBox(width: 8),
          Flexible(
            child: Text(message, style: TextStyle(fontSize: 12, color: tokens.ink2)),
          ),
        ],
      ),
    );
  }
}
