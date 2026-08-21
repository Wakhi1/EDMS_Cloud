import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/count_item.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/utils/file_saver/file_saver.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/compact_date_range_picker.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/label_value_bar_chart.dart';
import '../../../core/widgets/label_value_bar_list.dart';
import '../../../core/widgets/label_value_line_chart.dart';
import '../../departments/providers/departments_providers.dart';
import '../../repository/providers/repository_providers.dart';
import '../providers/reports_providers.dart';

const _kClassifications = <String>['public', 'internal', 'restricted', 'confidential'];
final _dateFormat = DateFormat('yyyy-MM-dd');

/// Reports lives in a true 4-per-row grid on desktop/tablet — unlike the
/// Integrations screen's MaxCrossAxisExtent precedent (an implicit column
/// count), this needs a literal "4 across" guarantee, so the column count
/// is computed directly from width instead.
int _columnsFor(double width) {
  if (width >= 900) return 4;
  if (width >= 600) return 2;
  return 1;
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _exporting = false;

  static const _mimeTypes = {
    'csv': 'text/csv',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'pdf': 'application/pdf',
  };

  Future<void> _export(String format) async {
    setState(() => _exporting = true);
    try {
      final f = ref.read(reportsFiltersProvider);
      final result = await ref.read(reportsApiProvider).export(
            format: format,
            from: f.from,
            to: f.to,
            departmentId: f.departmentId,
            documentTypeId: f.documentTypeId,
            folderId: f.folderId,
            classification: f.classification,
          );
      await saveBytes(bytes: result.bytes, fileName: result.fileName, mimeType: _mimeTypes[format]!);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded ${result.fileName}')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final filters = ref.read(reportsFiltersProvider);
    final initialFrom = filters.from != null ? DateTime.tryParse(filters.from!) : null;
    final initialTo = filters.to != null ? DateTime.tryParse(filters.to!) : null;

    final picked = await showCompactDateRangePicker(
      context,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      initialFrom: initialFrom,
      initialTo: initialTo,
    );
    if (picked == null) return;

    ref.read(reportsFiltersProvider.notifier).state = filters.copyWith(
      from: () => _dateFormat.format(picked.start),
      to: () => _dateFormat.format(picked.end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = _columnsFor(width);
    final filters = ref.watch(reportsFiltersProvider);
    final departmentsAsync = ref.watch(departmentsListProvider);
    final typesAsync = ref.watch(documentTypesProvider);
    final foldersAsync = ref.watch(foldersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Governance / Reports', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              PopupMenuButton<String>(
                enabled: !_exporting,
                onSelected: _export,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
                  PopupMenuItem(value: 'xlsx', child: Text('Export as Excel')),
                  PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(border: Border.all(color: context.tokens.line2)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _exporting
                          ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.download, size: 16, color: context.tokens.ink),
                      const SizedBox(width: 8),
                      const Text('Export report'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.calendar_today, size: 14),
                label: Text(filters.from != null && filters.to != null ? '${filters.from} → ${filters.to}' : 'Date range'),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<int?>(
                  initialValue: filters.departmentId,
                  isExpanded: true,
                  isDense: true,
                  decoration: const InputDecoration(labelText: 'Department', isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All departments')),
                    for (final d in departmentsAsync.valueOrNull ?? const []) DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => ref.read(reportsFiltersProvider.notifier).state = filters.copyWith(departmentId: () => v),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<int?>(
                  initialValue: filters.documentTypeId,
                  isExpanded: true,
                  isDense: true,
                  decoration: const InputDecoration(labelText: 'Document type', isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All types')),
                    for (final t in typesAsync.valueOrNull ?? const []) DropdownMenuItem(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => ref.read(reportsFiltersProvider.notifier).state = filters.copyWith(documentTypeId: () => v),
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int?>(
                  initialValue: filters.folderId,
                  isExpanded: true,
                  isDense: true,
                  decoration: const InputDecoration(labelText: 'Folder', isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All folders')),
                    for (final f in foldersAsync.valueOrNull ?? const []) DropdownMenuItem(value: f.id, child: Text(f.path, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => ref.read(reportsFiltersProvider.notifier).state = filters.copyWith(folderId: () => v),
                ),
              ),
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String?>(
                  initialValue: filters.classification,
                  isExpanded: true,
                  isDense: true,
                  decoration: const InputDecoration(labelText: 'Classification', isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All classifications')),
                    for (final c in _kClassifications) DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => ref.read(reportsFiltersProvider.notifier).state = filters.copyWith(classification: () => v),
                ),
              ),
              if (!filters.isEmpty)
                TextButton(
                  onPressed: () => ref.read(reportsFiltersProvider.notifier).state = const ReportsFilters(),
                  child: const Text('Clear filters'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 1.05,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            children: [
              _CountChartCard(title: 'Records by status', provider: reportsByStatusProvider, colorKey: _ChartColor.acc),
              _CountChartCard(title: 'Records by department', provider: reportsByDepartmentProvider, colorKey: _ChartColor.accD),
              _CountBarListCard(title: 'Records by category', provider: reportsByCategoryProvider, colorKey: _ChartColor.acc2, showSize: true),
              _CountBarListCard(title: 'Records by folder (top 15) — capacity', provider: reportsByFolderProvider, colorKey: _ChartColor.info, showSize: true),
              _CountChartCard(title: 'Records by classification', provider: reportsByClassificationProvider, colorKey: _ChartColor.warn),
              const _CapacityCard(),
              const _CaptureBySourceCard(),
              _CountLineChartCard(title: 'Records captured over time', provider: reportsCapturedOverTimeProvider, colorKey: _ChartColor.acc),
              const _ClaimTurnaroundCard(),
              const _RetentionStatusCard(),
              _CountBarListCard(title: 'Audit actions breakdown', provider: reportsAuditActionsProvider, colorKey: _ChartColor.bad),
              _CountBarListCard(title: 'Top audit actors', provider: reportsTopUsersProvider, colorKey: _ChartColor.accD),
            ],
          ),
        ],
      ),
    );
  }
}

enum _ChartColor { acc, accD, acc2, info, warn, bad }

Color _resolveColor(PspfTokens tokens, _ChartColor key) {
  return switch (key) {
    _ChartColor.acc => tokens.acc,
    _ChartColor.accD => tokens.accD,
    _ChartColor.acc2 => tokens.acc2,
    _ChartColor.info => tokens.info,
    _ChartColor.warn => tokens.warn,
    _ChartColor.bad => tokens.bad,
  };
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _CountChartCard extends ConsumerWidget {
  const _CountChartCard({required this.title, required this.provider, required this.colorKey});

  final String title;
  final ProviderListenable<AsyncValue<List<CountItem>>> provider;
  final _ChartColor colorKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final async = ref.watch(provider);

    return _SectionCard(
      title: title,
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.ink2), textAlign: TextAlign.center)),
        data: (counts) {
          if (counts.isEmpty) return const EmptyState(message: 'No data for this filter.');
          return LabelValueBarChart(points: [for (final c in counts) (c.label.replaceAll('_', ' '), c.total.toDouble())], color: _resolveColor(tokens, colorKey));
        },
      ),
    );
  }
}

class _CountBarListCard extends ConsumerWidget {
  const _CountBarListCard({required this.title, required this.provider, required this.colorKey, this.showSize = false});

  final String title;
  final ProviderListenable<AsyncValue<List<CountItem>>> provider;
  final _ChartColor colorKey;

  /// True for the by-category/by-folder cards ("file counts and size by
  /// document type" / "folder capacity") — folds each row's current-version
  /// total size into its label, since [LabelValueBarList]'s bar itself
  /// still tracks record count (its right-hand number stays the count that
  /// sizes the bar; size is supplementary context, not a second chart).
  final bool showSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final async = ref.watch(provider);

    return _SectionCard(
      title: title,
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.ink2), textAlign: TextAlign.center)),
        data: (counts) {
          if (counts.isEmpty) return const EmptyState(message: 'No data for this filter.');
          return LabelValueBarList(
            points: [
              for (final c in counts)
                (
                  showSize ? '${c.label.replaceAll('_', ' ')} — ${formatBytes(c.totalBytes ?? 0)}' : c.label.replaceAll('_', ' '),
                  c.total.toDouble(),
                ),
            ],
            color: _resolveColor(tokens, colorKey),
            valueSuffix: showSize ? ' files' : '',
          );
        },
      ),
    );
  }
}

class _CountLineChartCard extends ConsumerWidget {
  const _CountLineChartCard({required this.title, required this.provider, required this.colorKey});

  final String title;
  final ProviderListenable<AsyncValue<List<CountItem>>> provider;
  final _ChartColor colorKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final async = ref.watch(provider);

    return _SectionCard(
      title: title,
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.ink2), textAlign: TextAlign.center)),
        data: (counts) {
          if (counts.isEmpty) return const EmptyState(message: 'No data for this filter.');
          return LabelValueLineChart(points: [for (final c in counts) (c.label, c.total.toDouble())], color: _resolveColor(tokens, colorKey));
        },
      ),
    );
  }
}

class _CapacityCard extends ConsumerWidget {
  const _CapacityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final async = ref.watch(reportsCapacityProvider);

    return _SectionCard(
      title: 'Storage capacity',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.ink2), textAlign: TextAlign.center)),
        data: (stats) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatBytes(stats.usedBytes), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 28)),
              Text('of ${formatBytes(stats.capacityBytes)} (${(stats.usedFraction * 100).toStringAsFixed(1)}%)', style: TextStyle(color: tokens.ink2, fontSize: 12)),
              const SizedBox(height: 10),
              ClipRRect(
                child: LinearProgressIndicator(value: stats.usedFraction, minHeight: 8, backgroundColor: tokens.surf2, color: tokens.acc),
              ),
              const SizedBox(height: 10),
              Text('${stats.documentCount} documents · ${stats.objectCount} stored objects', style: TextStyle(color: tokens.ink2, fontSize: 11.5)),
            ],
          );
        },
      ),
    );
  }
}

class _CaptureBySourceCard extends ConsumerWidget {
  const _CaptureBySourceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final async = ref.watch(reportsCaptureBySourceProvider);

    return _SectionCard(
      title: 'Capture success by source',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.ink2), textAlign: TextAlign.center)),
        data: (rows) {
          // Not a plain LabelValueBarList: the bar here is an absolute 0-100
          // success-rate gauge (not proportional to the list's max), and each
          // row also carries a separate total-batches count — a genuinely
          // different two-number shape than the rest of this screen's cards.
          if (rows.isEmpty) return const EmptyState(message: 'No capture batches yet.');
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final r = rows[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(r.source, style: const TextStyle(fontSize: 12))),
                      Text('${r.total} · ${r.avgSuccessRate.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: tokens.ink2)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    child: LinearProgressIndicator(value: (r.avgSuccessRate / 100).clamp(0, 1), minHeight: 5, backgroundColor: tokens.surf2, color: tokens.acc),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ClaimTurnaroundCard extends ConsumerWidget {
  const _ClaimTurnaroundCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final async = ref.watch(reportsClaimTurnaroundProvider);

    return _SectionCard(
      title: 'Claim turnaround (avg days)',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.ink2), textAlign: TextAlign.center)),
        data: (points) {
          if (points.isEmpty) return const EmptyState(message: 'No decided workflow steps yet.');
          return LabelValueLineChart(points: [for (final p in points) (p.month, p.avgDaysToFirstDecision)], color: tokens.info);
        },
      ),
    );
  }
}

class _RetentionStatusCard extends ConsumerWidget {
  const _RetentionStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final async = ref.watch(reportsRetentionStatusProvider);

    return _SectionCard(
      title: 'Retention & disposal status',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.ink2), textAlign: TextAlign.center)),
        data: (rows) {
          if (rows.isEmpty) return const EmptyState(message: 'No data for this filter.');
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final r = rows[i];
              final fraction = r.total == 0 ? 0.0 : r.disposed / r.total;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(r.retentionClass, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
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
    );
  }
}
