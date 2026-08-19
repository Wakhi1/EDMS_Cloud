import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/audit_log_row.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/utils/file_saver/file_saver.dart';
import '../../../core/widgets/compact_date_range_picker.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/audit_providers.dart';

const _kAuditActions = <String>[
  'View', 'Edit', 'Approve', 'Capture', 'Download', 'Permission', 'Login', 'Login failed',
  'Integration', 'Declare record', 'Disposal', 'Create', 'Delete', 'MFA', 'Logout',
  'Backup', 'Restore',
];

final _dateFormat = DateFormat('yyyy-MM-dd');

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  bool _exporting = false;

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final f = ref.read(auditFiltersProvider);
      final result = await ref.read(auditApiProvider).exportCsv(action: f.action, recordType: f.recordType, q: f.q, from: f.from, to: f.to);
      await saveBytes(bytes: result.bytes, fileName: result.fileName, mimeType: 'text/csv');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded ${result.fileName}')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final logAsync = ref.watch(auditLogProvider);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Governance / Audit Trail', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              OutlinedButton(
                onPressed: _exporting ? null : _exportCsv,
                child: _exporting
                    ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Export audit log (CSV)'),
              ),
              const SizedBox(width: 8),
              const _VerifyChainButton(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'CSV export respects the filters below and is capped by the configured bulk export limit.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens.ink2),
          ),
          const SizedBox(height: 12),
          const _VerifyChainResult(),
          const _FilterBar(),
          const SizedBox(height: 12),
          Expanded(
            child: logAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: error is ApiException ? error.message : '$error',
                onRetry: () => ref.invalidate(auditLogProvider),
              ),
              data: (rows) => _AuditTable(rows: rows),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyChainButton extends ConsumerStatefulWidget {
  const _VerifyChainButton();

  @override
  ConsumerState<_VerifyChainButton> createState() => _VerifyChainButtonState();
}

class _VerifyChainButtonState extends ConsumerState<_VerifyChainButton> {
  bool _checking = false;

  Future<void> _verify() async {
    setState(() => _checking = true);
    ref.invalidate(auditVerifyChainProvider);
    try {
      await ref.read(auditVerifyChainProvider.future);
    } catch (_) {
      // Surfaced by the _VerifyChainResult widget's own .when(error:...).
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _checking ? null : _verify,
      child: _checking
          ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
          : const Text('Verify hash chain'),
    );
  }
}

class _VerifyChainResult extends ConsumerWidget {
  const _VerifyChainResult();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final result = ref.watch(auditVerifyChainProvider);

    return result.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.bad, fontSize: 12.5)),
      ),
      data: (r) {
        final color = r.valid ? tokens.ok : tokens.bad;
        final message = r.valid
            ? 'Hash chain verified — no gaps (${r.entries} entries).'
            : 'Hash chain broken at entry #${r.brokenAtId} (${r.entries} entries scanned).';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: tokens.surf2, border: Border(left: BorderSide(color: color, width: 3))),
            child: Text(message, style: TextStyle(color: color, fontSize: 12.5)),
          ),
        );
      },
    );
  }
}

class _FilterBar extends ConsumerStatefulWidget {
  const _FilterBar();

  @override
  ConsumerState<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<_FilterBar> {
  final _controller = TextEditingController();

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final filters = ref.read(auditFiltersProvider);
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

    ref.read(auditFiltersProvider.notifier).state = filters.copyWith(
      from: () => _dateFormat.format(picked.start),
      to: () => _dateFormat.format(picked.end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(auditFiltersProvider);
    final recordTypesAsync = ref.watch(auditRecordTypesProvider);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 36,
          child: TextField(
            controller: _controller,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(isDense: true, hintText: 'Search user, record, IP…', prefixIcon: Icon(Icons.search, size: 16)),
            onSubmitted: (q) {
              ref.read(auditFiltersProvider.notifier).state = filters.copyWith(q: q);
            },
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String>(
            initialValue: filters.action,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true, labelText: 'Action'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All actions')),
              for (final a in _kAuditActions) DropdownMenuItem(value: a, child: Text(a, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) {
              ref.read(auditFiltersProvider.notifier).state = filters.copyWith(action: () => v);
            },
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String>(
            initialValue: filters.recordType,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true, labelText: 'Record type'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All record types')),
              for (final t in recordTypesAsync.valueOrNull ?? const []) DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) {
              ref.read(auditFiltersProvider.notifier).state = filters.copyWith(recordType: () => v);
            },
          ),
        ),
        OutlinedButton.icon(
          onPressed: _pickDateRange,
          icon: const Icon(Icons.calendar_today, size: 14),
          label: Text(filters.from != null && filters.to != null ? '${filters.from} → ${filters.to}' : 'Date range'),
        ),
        if (filters.action != null || filters.recordType != null || filters.q.isNotEmpty || filters.from != null || filters.to != null)
          TextButton(
            onPressed: () {
              _controller.clear();
              ref.read(auditFiltersProvider.notifier).state = const AuditFilters();
            },
            child: const Text('Clear filters'),
          ),
      ],
    );
  }
}

class _AuditTable extends StatelessWidget {
  const _AuditTable({required this.rows});

  final List<AuditLogRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const EmptyState(message: 'No audit entries match these filters.');
    }
    final tokens = context.tokens;
    const flexes = [2, 2, 2, 2, 3, 2];

    Widget cell(String text, int flex) {
      return Expanded(flex: flex, child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 1));
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: tokens.surf2,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                cell('Time', flexes[0]),
                cell('User', flexes[1]),
                cell('Action', flexes[2]),
                cell('Record', flexes[3]),
                cell('Detail', flexes[4]),
                cell('IP', flexes[5]),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final r = rows[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.line))),
                  child: Row(
                    children: [
                      cell(r.createdAt.replaceFirst('T', ' ').split('.').first, flexes[0]),
                      cell(r.userName ?? '—', flexes[1]),
                      cell(r.action, flexes[2]),
                      cell(r.recordType != null ? '${r.recordType} #${r.recordId}' : '—', flexes[3]),
                      cell(r.detail ?? '—', flexes[4]),
                      cell(r.ipAddress ?? '—', flexes[5]),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
