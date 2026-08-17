import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/models/count_item.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/kpi_card.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Work / Records overview', style: Theme.of(context).textTheme.labelSmall),
          Text('Welcome, ${user?.fullName ?? ''}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          const _KpiRow(),
          const SizedBox(height: 22),
          Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: wide ? 2 : 1, child: const _StatusChartCard()),
              SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
              Expanded(child: const _ApprovalsPreviewCard()),
            ],
          ),
          const SizedBox(height: 22),
          Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
            children: [
              Expanded(child: const _CategoryChartCard()),
              SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
              Expanded(child: const _FolderChartCard()),
            ],
          ),
          const SizedBox(height: 22),
          const _NotificationsPreviewCard(),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
              ?action,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _KpiRow extends ConsumerWidget {
  const _KpiRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byStatus = ref.watch(dashboardByStatusProvider);
    final approvals = ref.watch(dashboardApprovalsProvider);
    final capacity = ref.watch(dashboardCapacityProvider);

    final total = byStatus.valueOrNull?.fold<int>(0, (sum, c) => sum + c.total);
    final pendingFromStatus = byStatus.valueOrNull?.where((c) => c.label == 'pending_approval').fold<int>(0, (s, c) => s + c.total);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 210,
          child: KpiCard(
            label: 'Total records',
            value: total?.toString() ?? (byStatus.hasError ? '—' : '…'),
            sub: byStatus.hasError ? 'Not available for your role' : 'Across all statuses',
            onTap: () => context.go(RoutePaths.repository),
          ),
        ),
        SizedBox(
          width: 210,
          child: KpiCard(
            label: 'Pending approval',
            value: (pendingFromStatus ?? 0).toString(),
            sub: byStatus.hasError ? 'Not available for your role' : 'From status breakdown',
          ),
        ),
        SizedBox(
          width: 210,
          child: KpiCard(
            label: 'Awaiting my approval',
            value: approvals.valueOrNull?.length.toString() ?? (approvals.hasError ? '—' : '…'),
            sub: approvals.hasError ? 'Not available for your role' : 'Your approval inbox',
            onTap: () => context.go('/approvals'),
          ),
        ),
        SizedBox(
          width: 210,
          child: KpiCard(
            label: 'Storage capacity',
            value: capacity.valueOrNull != null ? formatBytes(capacity.valueOrNull!.usedBytes) : (capacity.hasError ? '—' : '…'),
            sub: capacity.valueOrNull != null
                ? 'of ${formatBytes(capacity.valueOrNull!.capacityBytes)} (${(capacity.valueOrNull!.usedFraction * 100).toStringAsFixed(0)}%)'
                : (capacity.hasError ? 'Not available for your role' : null),
          ),
        ),
      ],
    );
  }
}

class _StatusChartCard extends ConsumerWidget {
  const _StatusChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final byStatus = ref.watch(dashboardByStatusProvider);

    return _SectionCard(
      title: 'Records by status',
      child: SizedBox(
        height: 220,
        child: byStatus.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.ink2), textAlign: TextAlign.center),
          ),
          data: (counts) {
            if (counts.isEmpty) return const EmptyState(message: 'No records yet.');
            return _BarChart(counts: counts, color: tokens.acc);
          },
        ),
      ),
    );
  }
}

class _CategoryChartCard extends ConsumerWidget {
  const _CategoryChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final byCategory = ref.watch(dashboardByCategoryProvider);

    return _SectionCard(
      title: 'Records by category',
      child: SizedBox(
        height: 220,
        child: byCategory.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.ink2), textAlign: TextAlign.center),
          ),
          data: (counts) {
            if (counts.isEmpty) return const EmptyState(message: 'No records yet.');
            return _BarChart(counts: counts, color: tokens.acc2);
          },
        ),
      ),
    );
  }
}

class _FolderChartCard extends ConsumerWidget {
  const _FolderChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final byFolder = ref.watch(dashboardByFolderProvider);

    return _SectionCard(
      title: 'Records by folder (top 15)',
      child: SizedBox(
        height: 220,
        child: byFolder.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.ink2), textAlign: TextAlign.center),
          ),
          data: (counts) {
            if (counts.isEmpty) return const EmptyState(message: 'No records yet.');
            return _BarChart(counts: counts, color: tokens.accD);
          },
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.counts, required this.color});

  final List<CountItem> counts;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxY = counts.map((c) => c.total).fold<int>(0, (a, b) => a > b ? a : b).toDouble();
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
                if (i < 0 || i >= counts.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(counts[i].label.replaceAll('_', ' '), style: const TextStyle(fontSize: 9)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < counts.length; i++)
            BarChartGroupData(x: i, barRods: [BarChartRodData(toY: counts[i].total.toDouble(), color: color, width: 22)]),
        ],
      ),
    );
  }
}

class _ApprovalsPreviewCard extends ConsumerWidget {
  const _ApprovalsPreviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final approvals = ref.watch(dashboardApprovalsProvider);

    return _SectionCard(
      title: 'Awaiting my approval',
      action: TextButton(onPressed: () => context.go('/approvals'), child: const Text('View all')),
      child: approvals.when(
        loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
        error: (e, _) => Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.ink2)),
        data: (items) {
          if (items.isEmpty) return const EmptyState(message: 'Inbox clear — no items pending your authorisation.');
          return Column(
            children: [
              for (final a in items.take(5))
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tokens.line))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('${a.recordNo} · ${a.stepName}', style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationsPreviewCard extends ConsumerWidget {
  const _NotificationsPreviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final notifs = ref.watch(dashboardNotificationsProvider);

    return _SectionCard(
      title: 'Activity',
      action: TextButton(onPressed: () => context.go('/notifications'), child: const Text('View all')),
      child: notifs.when(
        loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
        error: (e, _) => Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.ink2)),
        data: (items) {
          if (items.isEmpty) return const EmptyState(message: 'No recent activity.');
          return Column(
            children: [
              for (final n in items.take(6))
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tokens.line))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(fontSize: 12.5, fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
