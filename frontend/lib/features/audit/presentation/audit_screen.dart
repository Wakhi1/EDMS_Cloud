import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/audit_log_row.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/utils/file_saver/file_saver.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/widgets/compact_controls.dart';
import '../../../core/widgets/compact_date_range_picker.dart';
import '../../../core/widgets/empty_state.dart';
import '../../settings/providers/settings_providers.dart';
import '../providers/audit_providers.dart';

const _kAuditActions = <String>[
  'View',
  'Edit',
  'Approve',
  'Capture',
  'Download',
  'Permission',
  'Login',
  'Login failed',
  'Integration',
  'Declare record',
  'Disposal',
  'Create',
  'Delete',
  'MFA',
  'Logout',
  'Backup',
  'Restore',
];

final _dateFormat = DateFormat('yyyy-MM-dd');

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  bool _exporting = false;

  static const _mimeTypes = {'csv': 'text/csv', 'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'pdf': 'application/pdf'};

  Future<void> _export(String format) async {
    setState(() => _exporting = true);
    try {
      final f = ref.read(auditFiltersProvider);
      final api = ref.read(auditApiProvider);
      final result = switch (format) {
        'xlsx' => await api.exportXlsx(action: f.action, recordType: f.recordType, q: f.q, from: f.from, to: f.to),
        'pdf' => await api.exportPdf(action: f.action, recordType: f.recordType, q: f.q, from: f.from, to: f.to),
        _ => await api.exportCsv(action: f.action, recordType: f.recordType, q: f.q, from: f.from, to: f.to),
      };
      final saved = await saveBytes(bytes: result.bytes, fileName: result.fileName, mimeType: _mimeTypes[format]!);
      if (mounted && saved) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved ${result.fileName}')));
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
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Audit trail',
            breadcrumb: 'Governance / Audit trail — every view, change and sign-in, hash-chained',
            actions: [
              const _RetentionControl(),
              const _VerifyChainButton(),
              PopupMenuButton<String>(
                enabled: !_exporting,
                tooltip: 'Export the filtered entries',
                onSelected: _export,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'csv',
                    height: 34,
                    child: Text('CSV', style: TextStyle(fontSize: 12.5)),
                  ),
                  PopupMenuItem(
                    value: 'xlsx',
                    height: 34,
                    child: Text('Excel', style: TextStyle(fontSize: 12.5)),
                  ),
                  PopupMenuItem(
                    value: 'pdf',
                    height: 34,
                    child: Text('PDF', style: TextStyle(fontSize: 12.5)),
                  ),
                ],
                child: IgnorePointer(
                  child: CompactButton(label: 'Export', icon: Icons.download, busy: _exporting, onPressed: () {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _VerifyChainResult(),
          const _FilterBar(),
          const SizedBox(height: 10),
          Expanded(
            child: logAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(message: error is ApiException ? error.message : '$error', onRetry: () => ref.invalidate(auditLogProvider)),
              data: (rows) => _AuditTable(rows: rows),
            ),
          ),
          const SizedBox(height: 6),
          Text('Exports follow the filters above and are capped by the bulk export limit.', style: TextStyle(fontSize: 11, color: tokens.ink3)),
        ],
      ),
    );
  }
}

/// "Keep: 1 year" — how long audit entries are kept before the daily purge
/// removes them (system setting audit_retention_days). Only shown to roles
/// that can read settings; only a System Administrator can change it.
class _RetentionControl extends ConsumerWidget {
  const _RetentionControl();

  static const _options = <(int, String)>[
    (0, 'Forever'),
    (90, '90 days'),
    (180, '6 months'),
    (365, '1 year'),
    (730, '2 years'),
    (1095, '3 years'),
    (1825, '5 years'),
    (2555, '7 years'),
    (3650, '10 years'),
  ];

  static String _label(int days) {
    for (final (d, text) in _options) {
      if (d == days) {
        return text;
      }
    }
    return '$days days';
  }

  Future<void> _change(BuildContext context, WidgetRef ref, int current) async {
    var selected = current;
    final chosen = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final tokens = context.tokens;
          return AlertDialog(
            title: const Text('Keep audit entries for'),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final (d, text) in _options)
                        ChoiceChip(
                          label: Text(text, style: const TextStyle(fontSize: 12)),
                          selected: selected == d,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setState(() => selected = d),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tokens.warn.withValues(alpha: 0.08),
                      border: Border(left: BorderSide(color: tokens.warn, width: 3)),
                    ),
                    child: Text(
                      selected == 0
                          ? 'Nothing is ever deleted.'
                          : 'Once a day, entries older than ${_label(selected).toLowerCase()} are permanently deleted. '
                                'Export the audit log first if you need a copy. The hash chain stays verifiable, and each clean-up is itself logged.',
                      style: const TextStyle(fontSize: 12, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(selected), child: const Text('Save')),
            ],
          );
        },
      ),
    );
    if (chosen == null || chosen == current) return;
    try {
      await ref.read(settingsApiProvider).update('audit_retention_days', '$chosen');
      ref.invalidate(systemSettingsListProvider);
      final kept = chosen == 0 ? 'forever' : 'for ${_label(chosen).toLowerCase()}';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Audit entries are now kept $kept.')));
      }
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserProvider)?.role;
    // GET /api/settings is admin/records-manager only; never call it for other roles.
    if (role != 'System Administrator' && role != 'Records Manager') return const SizedBox.shrink();
    final settings = ref.watch(systemSettingsListProvider).valueOrNull;
    final row = settings?.where((s) => s.key == 'audit_retention_days').firstOrNull;
    if (row == null) return const SizedBox.shrink();
    final days = int.tryParse(row.value) ?? 0;
    return Tooltip(
      message: role == 'System Administrator' ? 'Change how long audit entries are kept' : 'Only a System Administrator can change this',
      child: CompactButton(
        label: 'Keep: ${_label(days)}',
        icon: Icons.history_toggle_off,
        onPressed: role == 'System Administrator' ? () => _change(context, ref, days) : null,
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
    return CompactButton(label: 'Verify chain', icon: Icons.verified_outlined, busy: _checking, onPressed: _verify);
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
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.bad, fontSize: 12)),
      ),
      data: (r) {
        final color = r.valid ? tokens.ok : tokens.bad;
        final message = r.valid
            ? 'Hash chain verified — no gaps (${r.entries} entries).'
            : 'Hash chain broken at entry #${r.brokenAtId} (${r.entries} entries scanned).';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              border: Border(left: BorderSide(color: color, width: 3)),
            ),
            child: Row(
              children: [
                Icon(r.valid ? Icons.check_circle : Icons.error_outline, size: 15, color: color),
                const SizedBox(width: 6),
                Text(message, style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final filters = ref.read(auditFiltersProvider);
    final initialFrom = filters.from != null ? DateTime.tryParse(filters.from!) : null;
    final initialTo = filters.to != null ? DateTime.tryParse(filters.to!) : null;

    final picked = await showCompactDateRangePicker(context, firstDate: DateTime(now.year - 10), lastDate: now, initialFrom: initialFrom, initialTo: initialTo);
    if (picked == null) return;

    ref.read(auditFiltersProvider.notifier).state = filters.copyWith(from: () => _dateFormat.format(picked.start), to: () => _dateFormat.format(picked.end));
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(auditFiltersProvider);
    final recordTypes = ref.watch(auditRecordTypesProvider).valueOrNull ?? const <String>[];
    final hasFilters = filters.action != null || filters.recordType != null || filters.q.isNotEmpty || filters.from != null || filters.to != null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CompactSearchField(
          controller: _controller,
          hint: 'Search user, record, IP…',
          onSubmitted: (q) => ref.read(auditFiltersProvider.notifier).state = filters.copyWith(q: q),
        ),
        CompactSelect<String?>(
          width: 180,
          label: 'Action',
          value: filters.action,
          items: [(null, 'All'), for (final a in _kAuditActions) (a, a)],
          onChanged: (v) => ref.read(auditFiltersProvider.notifier).state = filters.copyWith(action: () => v),
        ),
        CompactSelect<String?>(
          width: 190,
          label: 'Record',
          value: filters.recordType,
          items: [(null, 'All'), for (final t in recordTypes) (t, t)],
          onChanged: (v) => ref.read(auditFiltersProvider.notifier).state = filters.copyWith(recordType: () => v),
        ),
        CompactButton(
          label: filters.from != null && filters.to != null ? '${filters.from} → ${filters.to}' : 'Any date',
          icon: Icons.calendar_today,
          onPressed: _pickDateRange,
        ),
        if (hasFilters)
          TextButton(
            onPressed: () {
              _controller.clear();
              ref.read(auditFiltersProvider.notifier).state = const AuditFilters();
            },
            child: const Text('Clear', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}

class _AuditTable extends StatelessWidget {
  const _AuditTable({required this.rows});

  final List<AuditLogRow> rows;

  static Color _actionColor(PspfTokens t, String action) => switch (action) {
    'Delete' || 'Disposal' || 'Login failed' => t.bad,
    'Edit' || 'Permission' || 'Restore' => t.warn,
    'Create' || 'Approve' || 'Capture' || 'Declare record' || 'Backup' => t.ok,
    'Login' || 'Logout' || 'MFA' => t.info,
    _ => t.ink2,
  };

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const EmptyState(message: 'No audit entries match these filters.');
    final tokens = context.tokens;
    const flexes = [3, 3, 2, 3, 6, 2];

    Widget cell(String text, int flex, {Color? color, FontWeight? weight}) => Expanded(
      flex: flex,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(fontSize: 12, color: color, fontWeight: weight),
      ),
    );
    Widget head(String text, int flex) => Expanded(
      flex: flex,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 10.5, letterSpacing: 0.5, fontWeight: FontWeight.w700, color: tokens.ink2),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.line),
        color: tokens.surf,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: tokens.surf2,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                head('Time', flexes[0]),
                head('User', flexes[1]),
                head('Action', flexes[2]),
                head('Record', flexes[3]),
                head('Detail', flexes[4]),
                head('IP', flexes[5]),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemExtent: 32,
              itemBuilder: (context, i) {
                final r = rows[i];
                final color = _actionColor(tokens, r.action);
                return Tooltip(
                  message: r.detail ?? '',
                  waitDuration: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: i.isOdd ? tokens.surf2.withValues(alpha: 0.35) : null,
                      border: Border(top: BorderSide(color: tokens.line)),
                    ),
                    child: Row(
                      children: [
                        cell(r.createdAt.replaceFirst('T', ' ').split('.').first, flexes[0], color: tokens.ink2),
                        cell(r.userName ?? 'System', flexes[1], weight: FontWeight.w500),
                        Expanded(
                          flex: flexes[2],
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                border: Border.all(color: color.withValues(alpha: 0.5)),
                                color: color.withValues(alpha: 0.07),
                              ),
                              child: Text(
                                r.action,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: color),
                              ),
                            ),
                          ),
                        ),
                        cell(r.recordType != null ? '${r.recordType} #${r.recordId}' : '—', flexes[3], color: tokens.ink2),
                        cell(r.detail ?? '—', flexes[4]),
                        cell(r.ipAddress ?? '—', flexes[5], color: tokens.ink3),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: tokens.surf2,
              border: Border(top: BorderSide(color: tokens.line)),
            ),
            child: Text('${rows.length} entr${rows.length == 1 ? 'y' : 'ies'}', style: TextStyle(fontSize: 11, color: tokens.ink2)),
          ),
        ],
      ),
    );
  }
}
