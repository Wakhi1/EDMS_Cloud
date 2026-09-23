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
import '../../../core/widgets/label_value_line_chart.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final summary = ref.watch(dashboardSummaryProvider).valueOrNull;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    Widget pair(Widget a, Widget? b, {int flexA = 1}) {
      if (b == null) return a;
      return Flex(
        direction: wide ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: wide ? flexA : 1, child: a),
          SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
          Expanded(child: b),
        ],
      );
    }

    // Sections the role can't see (null in the summary) are left out entirely.
    final hasDocuments = summary?.documents != null;
    final hasStorage = summary?.storage != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Work / Records overview', style: Theme.of(context).textTheme.labelSmall),
                    Text('Welcome, ${user?.fullName ?? ''}', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(dashboardSummaryProvider);
                  ref.invalidate(dashboardApprovalsProvider);
                  ref.invalidate(dashboardOverdueRetentionProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _KpiRow(),
          const SizedBox(height: 22),
          pair(hasDocuments ? const _StatusCard() : const _ApprovalsPreviewCard(), hasDocuments ? const _ApprovalsPreviewCard() : null, flexA: 2),
          if (hasStorage || hasDocuments) ...[
            const SizedBox(height: 22),
            pair(hasStorage ? const _StorageByLocationCard() : const _DocumentTypesCard(), hasStorage && hasDocuments ? const _DocumentTypesCard() : null),
          ],
          const SizedBox(height: 22),
          pair(const _FolderChartCard(), const _CapturedOverTimeCard()),
          const SizedBox(height: 22),
          pair(const _RetentionStatusPreviewCard(), const _NotificationsPreviewCard()),
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
      decoration: BoxDecoration(
        border: Border.all(color: tokens.line),
        color: tokens.surf,
      ),
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
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final approvals = ref.watch(dashboardApprovalsProvider);
    final overdue = ref.watch(dashboardOverdueRetentionProvider);
    final summary = summaryAsync.valueOrNull;
    final docs = summary?.documents;
    final folders = summary?.folders;
    final storage = summary?.storage;
    final pending = summaryAsync.isLoading ? '…' : '—';

    Widget kpi(String label, String value, String? sub, {VoidCallback? onTap}) => SizedBox(
      width: 200,
      child: KpiCard(label: label, value: value, sub: sub, onTap: onTap),
    );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (docs != null || summaryAsync.isLoading) ...[
          kpi(
            'Documents',
            docs?.live.toString() ?? pending,
            docs == null ? null : '${docs.total} incl. archived/disposed',
            onTap: () => context.go(RoutePaths.repository),
          ),
          kpi('Files', docs?.fileCount.toString() ?? pending, docs == null ? null : '${docs.currentFileCount} current · ${formatBytes(docs.currentBytes)}'),
          kpi(
            'Pages',
            docs == null ? pending : '${docs.pagesEstimated ? '~' : ''}${docs.pageCount}',
            docs == null ? null : (docs.uncountedFiles > 0 ? '${docs.uncountedFiles} file(s) not countable' : 'Across current versions'),
          ),
          kpi('Pending approval', docs?.statusCount('pending_approval').toString() ?? pending, 'Documents in workflow'),
          kpi('My records', docs?.mine.toString() ?? pending, docs == null ? null : '${docs.createdThisMonth} added this month'),
        ],
        if (folders != null)
          kpi('Folders', folders.total.toString(), '${folders.topLevel} top-level · ${folders.empty} empty', onTap: () => context.go(RoutePaths.repository)),
        if (storage != null) kpi('Storage used', formatBytes(storage.usedBytes), '${storage.objectCount} objects · ${storage.locations.length} location(s)'),
        if (!approvals.hasError)
          kpi('Awaiting my approval', approvals.valueOrNull?.length.toString() ?? '…', 'Your approval inbox', onTap: () => context.go('/approvals')),
        if (!overdue.hasError)
          kpi('Overdue for disposal', overdue.valueOrNull?.toString() ?? '…', 'Past their retention due date', onTap: () => context.go('/retention')),
      ],
    );
  }
}

/// Every status is listed (including zero counts) so the lifecycle reads end to end.
class _StatusCard extends ConsumerWidget {
  const _StatusCard();

  static const _labels = {
    'draft': 'Draft',
    'pending_approval': 'Pending approval',
    'approved': 'Approved',
    'rejected': 'Rejected',
    'declared_final': 'Declared final',
    'archived': 'Archived (recycle bin)',
    'disposed': 'Disposed',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final async = ref.watch(dashboardSummaryProvider);
    final colors = {
      'draft': tokens.ink3,
      'pending_approval': tokens.warn,
      'approved': tokens.ok,
      'rejected': tokens.bad,
      'declared_final': tokens.acc,
      'archived': tokens.ink2,
      'disposed': tokens.line2,
    };

    return _SectionCard(
      title: 'Documents by status',
      action: TextButton(onPressed: () => context.go(RoutePaths.repository), child: const Text('Repository')),
      child: async.when(
        loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
        error: (e, _) => Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.ink2)),
        data: (summary) {
          final docs = summary.documents;
          if (docs == null) return const SizedBox.shrink();
          final max = docs.byStatus.fold<int>(0, (m, c) => c.total > m ? c.total : m);
          return Column(
            children: [
              for (final c in docs.byStatus)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(width: 150, child: Text(_labels[c.label] ?? c.label, style: const TextStyle(fontSize: 12.5))),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: max == 0 ? 0 : c.total / max,
                          minHeight: 10,
                          backgroundColor: tokens.surf2,
                          color: colors[c.label] ?? tokens.acc,
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${c.total}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
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

class _StorageByLocationCard extends ConsumerWidget {
  const _StorageByLocationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final storage = ref.watch(dashboardSummaryProvider).valueOrNull?.storage;
    if (storage == null) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Storage by location',
      child: storage.locations.isEmpty
          ? const EmptyState(message: 'No storage locations configured.')
          : Column(
              children: [
                for (final l in storage.locations)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.circle, size: 9, color: l.status == 'connected' ? tokens.ok : (l.status == 'error' ? tokens.bad : tokens.ink3)),
                            const SizedBox(width: 6),
                            Text(l.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            if (l.active) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                color: tokens.accT,
                                child: Text(
                                  'ACTIVE',
                                  style: TextStyle(fontSize: 9.5, color: tokens.accD, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              l.capacityBytes > 0
                                  ? '${formatBytes(l.usedBytes)} of ${formatBytes(l.capacityBytes)}'
                                  : '${formatBytes(l.usedBytes)} · no capacity set',
                              style: TextStyle(fontSize: 11.5, color: tokens.ink2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        LinearProgressIndicator(
                          value: l.capacityBytes > 0 ? l.usedFraction : 0,
                          minHeight: 8,
                          backgroundColor: tokens.surf2,
                          color: l.usedFraction > 0.9 ? tokens.bad : (l.usedFraction > 0.75 ? tokens.warn : tokens.acc),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${l.objectCount} object(s)${l.capacityBytes > 0 ? ' · ${(l.usedFraction * 100).toStringAsFixed(1)}% used' : ''}',
                          style: TextStyle(fontSize: 11, color: tokens.ink3),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _DocumentTypesCard extends ConsumerWidget {
  const _DocumentTypesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final docs = ref.watch(dashboardSummaryProvider).valueOrNull?.documents;
    if (docs == null) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Documents by type',
      child: SizedBox(
        height: 220,
        child: docs.byType.isEmpty ? const EmptyState(message: 'No records yet.') : _BarChart(counts: docs.byType, color: tokens.acc2),
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
            child: Text(
              e is ApiException ? e.message : '$e',
              style: TextStyle(color: tokens.ink2),
              textAlign: TextAlign.center,
            ),
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
            BarChartGroupData(
              x: i,
              barRods: [BarChartRodData(toY: counts[i].total.toDouble(), color: color, width: 22, borderRadius: BorderRadius.zero)],
            ),
        ],
      ),
    );
  }
}

class _CapturedOverTimeCard extends ConsumerWidget {
  const _CapturedOverTimeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final async = ref.watch(dashboardCapturedOverTimeProvider);

    return _SectionCard(
      title: 'Records captured over time',
      child: SizedBox(
        height: 220,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              e is ApiException ? e.message : '$e',
              style: TextStyle(color: tokens.ink2),
              textAlign: TextAlign.center,
            ),
          ),
          data: (counts) {
            if (counts.isEmpty) return const EmptyState(message: 'No records yet.');
            return LabelValueLineChart(points: [for (final c in counts) (c.label, c.total.toDouble())], color: tokens.acc);
          },
        ),
      ),
    );
  }
}

class _RetentionStatusPreviewCard extends ConsumerWidget {
  const _RetentionStatusPreviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final async = ref.watch(dashboardRetentionStatusProvider);

    return _SectionCard(
      title: 'Retention & disposal status',
      action: TextButton(onPressed: () => context.go('/retention'), child: const Text('View all')),
      child: SizedBox(
        height: 220,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              e is ApiException ? e.message : '$e',
              style: TextStyle(color: tokens.ink2),
              textAlign: TextAlign.center,
            ),
          ),
          data: (rows) {
            if (rows.isEmpty) return const EmptyState(message: 'No data yet.');
            return ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = rows[i];
                final fraction = r.total == 0 ? 0.0 : r.disposed / r.total;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(r.retentionClass, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        ),
                        Text('${r.disposed}/${r.total} disposed', style: TextStyle(fontSize: 11, color: tokens.ink2)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      child: LinearProgressIndicator(value: fraction, minHeight: 5, backgroundColor: tokens.surf2, color: tokens.warn),
                    ),
                  ],
                );
              },
            );
          },
        ),
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
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: tokens.line)),
                  ),
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
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: tokens.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(n.title, style: TextStyle(fontSize: 12.5, fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w700)),
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
