import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/count_item.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/utils/file_saver/file_saver.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/compact_controls.dart';
import '../../../core/widgets/compact_date_range_picker.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/label_value_bar_chart.dart';
import '../../../core/widgets/label_value_bar_list.dart';
import '../../../core/widgets/label_value_line_chart.dart';
import '../../departments/providers/departments_providers.dart';
import '../../repository/providers/repository_providers.dart';
import '../providers/reports_providers.dart';
import 'widgets/customize_report_dialog.dart';
import 'widgets/export_report_dialog.dart';

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

  static const _mimeTypes = {'csv': 'text/csv', 'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'pdf': 'application/pdf'};

  Future<void> _openExportDialog() async {
    final result = await showDialog<({String format, bool includeSignature})>(context: context, builder: (_) => const ExportReportDialog());
    if (result == null) return;
    await _export(result.format, includeSignature: result.includeSignature);
  }

  Future<void> _openCustomizeDialog() {
    return showDialog<void>(context: context, builder: (_) => const CustomizeReportDialog());
  }

  Future<void> _export(String format, {bool includeSignature = false}) async {
    setState(() => _exporting = true);
    try {
      final f = ref.read(reportsFiltersProvider);
      final sections = ref.read(selectedReportSectionsProvider);
      final result = await ref
          .read(reportsApiProvider)
          .export(
            format: format,
            from: f.from,
            to: f.to,
            departmentId: f.departmentId,
            documentTypeId: f.documentTypeId,
            folderId: f.folderId,
            classification: f.classification,
            sections: sections.toList(),
            includeSignature: includeSignature,
          );
      final saved = await saveBytes(bytes: result.bytes, fileName: result.fileName, mimeType: _mimeTypes[format]!);
      if (mounted && saved) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved ${result.fileName}')));
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

    final picked = await showCompactDateRangePicker(context, firstDate: DateTime(now.year - 10), lastDate: now, initialFrom: initialFrom, initialTo: initialTo);
    if (picked == null) return;

    ref.read(reportsFiltersProvider.notifier).state = filters.copyWith(from: () => _dateFormat.format(picked.start), to: () => _dateFormat.format(picked.end));
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
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Reports',
            breadcrumb: 'Governance / Reports — filter once, every section follows',
            actions: [
              CompactButton(label: 'Customize', icon: Icons.tune, onPressed: _openCustomizeDialog),
              CompactButton(label: 'Export', icon: Icons.download, busy: _exporting, primary: true, onPressed: _openExportDialog),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.tokens.surf2,
              border: Border.all(color: context.tokens.line),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CompactButton(
                  label: filters.from != null && filters.to != null ? '${filters.from} → ${filters.to}' : 'Any date',
                  icon: Icons.calendar_today,
                  onPressed: _pickDateRange,
                ),
                CompactSelect<int?>(
                  width: 200,
                  label: 'Department',
                  value: filters.departmentId,
                  items: [(null, 'All'), for (final d in departmentsAsync.valueOrNull ?? const []) (d.id as int?, d.name as String)],
                  onChanged: (v) => ref.read(reportsFiltersProvider.notifier).state = filters.copyWith(departmentId: () => v),
                ),
                CompactSelect<int?>(
                  width: 200,
                  label: 'Type',
                  value: filters.documentTypeId,
                  items: [(null, 'All'), for (final t in typesAsync.valueOrNull ?? const []) (t.id as int?, t.name as String)],
                  onChanged: (v) => ref.read(reportsFiltersProvider.notifier).state = filters.copyWith(documentTypeId: () => v),
                ),
                CompactSelect<int?>(
                  width: 220,
                  label: 'Folder',
                  value: filters.folderId,
                  items: [(null, 'All'), for (final f in foldersAsync.valueOrNull ?? const []) (f.id as int?, f.path as String)],
                  onChanged: (v) => ref.read(reportsFiltersProvider.notifier).state = filters.copyWith(folderId: () => v),
                ),
                CompactSelect<String?>(
                  width: 190,
                  label: 'Access',
                  value: filters.classification,
                  items: [(null, 'All'), for (final c in _kClassifications) (c, c)],
                  onChanged: (v) => ref.read(reportsFiltersProvider.notifier).state = filters.copyWith(classification: () => v),
                ),
                if (!filters.isEmpty)
                  TextButton(
                    onPressed: () => ref.read(reportsFiltersProvider.notifier).state = const ReportsFilters(),
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, childAspectRatio: 1.3, crossAxisSpacing: 10, mainAxisSpacing: 10),
            // Keyed by the same section keys as kReportSectionDefs (see
            // reports_providers.dart) and built in that same order, so
            // "Customize" and GET /export always agree on what a section is.
            children: [
              for (final entry in {
                'by-status': _CountChartCard(title: 'Records by status', provider: reportsByStatusProvider, colorKey: _ChartColor.acc),
                'by-department': _CountChartCard(title: 'Records by department', provider: reportsByDepartmentProvider, colorKey: _ChartColor.accD),
                'by-category': _CountBarListCard(title: 'Records by category', provider: reportsByCategoryProvider, colorKey: _ChartColor.acc2, showSize: true),
                'by-folder': _CountBarListCard(
                  title: 'Records by folder (top 15) — capacity',
                  provider: reportsByFolderProvider,
                  colorKey: _ChartColor.info,
                  showSize: true,
                ),
                'by-classification': _CountChartCard(title: 'Records by classification', provider: reportsByClassificationProvider, colorKey: _ChartColor.warn),
                'capacity': const _CapacityCard(),
                'captured-over-time': _CountLineChartCard(
                  title: 'Records captured over time',
                  provider: reportsCapturedOverTimeProvider,
                  colorKey: _ChartColor.acc,
                ),
                'capture-by-source': const _CaptureBySourceCard(),
                'claim-turnaround': const _ClaimTurnaroundCard(),
                'retention-status': const _RetentionStatusCard(),
                'overdue-retention': const _OverdueRetentionCard(),
                'audit-actions': _CountBarListCard(title: 'Audit actions breakdown', provider: reportsAuditActionsProvider, colorKey: _ChartColor.bad),
                'top-users': _CountBarListCard(title: 'Top audit actors', provider: reportsTopUsersProvider, colorKey: _ChartColor.accD),
              }.entries)
                if (ref.watch(selectedReportSectionsProvider).contains(entry.key)) entry.value,
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
      decoration: BoxDecoration(
        border: Border.all(color: tokens.line),
        color: tokens.surf,
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
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
        error: (e, _) => Center(
          child: Text(
            e is ApiException ? e.message : '$e',
            style: TextStyle(color: tokens.ink2),
            textAlign: TextAlign.center,
          ),
        ),
        data: (counts) {
          if (counts.isEmpty) return const EmptyState(message: 'No data for this filter.');
          return LabelValueBarChart(
            points: [for (final c in counts) (c.label.replaceAll('_', ' '), c.total.toDouble())],
            color: _resolveColor(tokens, colorKey),
          );
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
        error: (e, _) => Center(
          child: Text(
            e is ApiException ? e.message : '$e',
            style: TextStyle(color: tokens.ink2),
            textAlign: TextAlign.center,
          ),
        ),
        data: (counts) {
          if (counts.isEmpty) return const EmptyState(message: 'No data for this filter.');
          return LabelValueBarList(
            points: [
              for (final c in counts)
                (showSize ? '${c.label.replaceAll('_', ' ')} — ${formatBytes(c.totalBytes ?? 0)}' : c.label.replaceAll('_', ' '), c.total.toDouble()),
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
        error: (e, _) => Center(
          child: Text(
            e is ApiException ? e.message : '$e',
            style: TextStyle(color: tokens.ink2),
            textAlign: TextAlign.center,
          ),
        ),
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
        error: (e, _) => Center(
          child: Text(
            e is ApiException ? e.message : '$e',
            style: TextStyle(color: tokens.ink2),
            textAlign: TextAlign.center,
          ),
        ),
        data: (stats) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatBytes(stats.usedBytes), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 28)),
              Text(
                'of ${formatBytes(stats.capacityBytes)} (${(stats.usedFraction * 100).toStringAsFixed(1)}%)',
                style: TextStyle(color: tokens.ink2, fontSize: 12),
              ),
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
        error: (e, _) => Center(
          child: Text(
            e is ApiException ? e.message : '$e',
            style: TextStyle(color: tokens.ink2),
            textAlign: TextAlign.center,
          ),
        ),
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
        error: (e, _) => Center(
          child: Text(
            e is ApiException ? e.message : '$e',
            style: TextStyle(color: tokens.ink2),
            textAlign: TextAlign.center,
          ),
        ),
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
        error: (e, _) => Center(
          child: Text(
            e is ApiException ? e.message : '$e',
            style: TextStyle(color: tokens.ink2),
            textAlign: TextAlign.center,
          ),
        ),
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
    );
  }
}

/// Was previously a Dashboard-only KPI (GET /reports/overdue-retention);
/// promoted to its own Reports card so it can be included/excluded by the
/// "Customize" section picker like every other card.
class _OverdueRetentionCard extends ConsumerWidget {
  const _OverdueRetentionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final async = ref.watch(reportsOverdueRetentionProvider);

    return _SectionCard(
      title: 'Overdue for disposal',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e is ApiException ? e.message : '$e',
            style: TextStyle(color: tokens.ink2),
            textAlign: TextAlign.center,
          ),
        ),
        data: (count) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$count', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 32, color: count > 0 ? tokens.bad : tokens.ink)),
              const SizedBox(height: 6),
              Text(
                'records past their retention due date',
                style: TextStyle(color: tokens.ink2, fontSize: 11.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
