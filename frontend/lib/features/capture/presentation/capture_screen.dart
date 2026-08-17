import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/capture_batch_row.dart';
import '../../../core/models/capture_batch_summary.dart';
import '../../../core/models/folder_row.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/utils/file_saver/file_saver.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/label_value_bar_chart.dart';
import '../../../core/widgets/status_chip.dart';
import '../../repository/providers/repository_providers.dart';
import '../providers/capture_providers.dart';
import 'record_capture_batch_dialog.dart';
import 'widgets/batch_detail_dialog.dart';
import 'widgets/new_batch_dialog.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  bool _exporting = false;

  void _refresh() {
    ref.invalidate(captureBatchesSummaryProvider);
    ref.invalidate(captureBatchListProvider);
    ref.invalidate(captureConnectorStatusProvider);
  }

  Future<void> _newBatch() async {
    List<FolderRow> folders;
    try {
      folders = await ref.read(foldersProvider.future);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (folders.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No repository folders exist yet — create one in Repository first.')));
      return;
    }
    if (!mounted) return;
    final result = await NewBatchDialog.show(context, folders: folders);
    if (result == null) return;

    try {
      final outcome = await ref.read(captureBatchesApiProvider).upload(files: result.files, source: result.source, folderId: result.folderId);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Batch ${outcome.batchNo}: ${outcome.succeeded}/${outcome.total} captured')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _recordBatch() async {
    final result = await showDialog<({String batchNo, String source, int pages, int documents, double successRate})>(
      context: context,
      builder: (_) => const RecordCaptureBatchDialog(),
    );
    if (result == null) return;

    try {
      await ref.read(captureBatchesApiProvider).recordBatch(
            batchNo: result.batchNo,
            source: result.source,
            pages: result.pages,
            documents: result.documents,
            successRate: result.successRate,
          );
      _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch recorded.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final result = await ref.read(captureBatchesApiProvider).exportCsv();
      await saveBytes(bytes: result.bytes, fileName: result.fileName, mimeType: 'text/csv');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded ${result.fileName}')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final summaryAsync = ref.watch(captureBatchesSummaryProvider);
    final batchesAsync = ref.watch(captureBatchListProvider);
    final connectorsAsync = ref.watch(captureConnectorStatusProvider);
    final filters = ref.watch(captureBatchFiltersProvider);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Text('Records / Capture & Scan', style: Theme.of(context).textTheme.titleMedium);
              final controls = Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 170,
                    child: DropdownButtonFormField<String?>(
                      initialValue: filters.source,
                      isDense: true,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Source', isDense: true),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All sources', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'manual_upload', child: Text('Manual upload', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'device_upload', child: Text('Device upload', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'watched_folder', child: Text('Watched folder', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'ftp', child: Text('FTP', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'email_intake', child: Text('Email intake', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'network_scanner', child: Text('Network scanner', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => ref.read(captureBatchFiltersProvider.notifier).state = filters.copyWith(source: () => v),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: DropdownButtonFormField<String?>(
                      initialValue: filters.status,
                      isDense: true,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Status', isDense: true),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All statuses', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'running', child: Text('Running', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'completed', child: Text('Completed', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'completed_with_errors', child: Text('Completed w/ errors', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'failed', child: Text('Failed', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => ref.read(captureBatchFiltersProvider.notifier).state = filters.copyWith(status: () => v),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _exporting ? null : _exportCsv,
                    child: _exporting
                        ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Export CSV'),
                  ),
                  OutlinedButton(onPressed: _recordBatch, child: const Text('Log batch')),
                  ElevatedButton(onPressed: _newBatch, child: const Text('New batch')),
                ],
              );

              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 10), controls],
                );
              }
              return Row(
                children: [title, const SizedBox(width: 16), Expanded(child: Align(alignment: Alignment.centerRight, child: controls))],
              );
            },
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  summaryAsync.when(
                    loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                    error: (error, _) => Text(error is ApiException ? error.message : '$error', style: TextStyle(color: tokens.bad)),
                    data: (rows) => rows.isEmpty
                        ? const EmptyState(message: 'No capture activity yet — start a new batch to see stats here.')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _KpiRow(rows: rows),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Documents captured by source', style: Theme.of(context).textTheme.titleSmall),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 180,
                                      child: LabelValueBarChart(
                                        points: [for (final r in rows) (r.source.replaceAll('_', ' '), r.totalDocuments.toDouble())],
                                        color: tokens.acc,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  _AutomationStatusPanel(connectorsAsync: connectorsAsync),
                  const SizedBox(height: 16),
                  Text('Batches', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  batchesAsync.when(
                    loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                    error: (error, _) => Text(error is ApiException ? error.message : '$error', style: TextStyle(color: tokens.bad)),
                    data: (batches) {
                      if (batches.isEmpty) return const EmptyState(message: 'No batches yet.');
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
                                  Expanded(flex: 2, child: Text('Batch', style: Theme.of(context).textTheme.labelSmall)),
                                  Expanded(child: Text('Source', style: Theme.of(context).textTheme.labelSmall)),
                                  Expanded(child: Text('Status', style: Theme.of(context).textTheme.labelSmall)),
                                  Expanded(child: Text('Docs', style: Theme.of(context).textTheme.labelSmall)),
                                  Expanded(child: Text('Success', style: Theme.of(context).textTheme.labelSmall)),
                                  Expanded(flex: 2, child: Text('Started', style: Theme.of(context).textTheme.labelSmall)),
                                ],
                              ),
                            ),
                            for (final b in batches) _BatchRow(batch: b),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({required this.batch});

  final CaptureBatchRow batch;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: () => showDialog(context: context, builder: (_) => BatchDetailDialog(batchId: batch.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.line))),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(batch.batchNo, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis)),
            Expanded(child: Text(batch.source.replaceAll('_', ' '), style: const TextStyle(fontSize: 12.5))),
            Expanded(
              child: StatusChip(
                batch.status.replaceAll('_', ' '),
                tone: batch.status == 'completed' ? StatusTone.ok : (batch.status == 'failed' ? StatusTone.bad : StatusTone.warn),
              ),
            ),
            Expanded(child: Text('${batch.documents}', style: const TextStyle(fontSize: 12.5))),
            Expanded(child: Text('${batch.successRate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12.5))),
            Expanded(flex: 2, child: Text(batch.startedAt ?? '—', style: TextStyle(fontSize: 11.5, color: tokens.ink2))),
          ],
        ),
      ),
    );
  }
}

class _AutomationStatusPanel extends StatelessWidget {
  const _AutomationStatusPanel({required this.connectorsAsync});

  final AsyncValue<List<CaptureConnectorStatus>> connectorsAsync;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Automated intake', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Network/connected scanners feed in via "scan to folder" or "scan to email" — point the device at Watched Folder or Email Intake below. Configure connection details in Integrations.',
            style: TextStyle(fontSize: 11.5, color: tokens.ink2),
          ),
          const SizedBox(height: 10),
          connectorsAsync.when(
            loading: () => const SizedBox(height: 24, child: LinearProgressIndicator()),
            error: (error, _) => Text('$error', style: TextStyle(color: tokens.bad, fontSize: 12)),
            data: (connectors) => Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final c in connectors)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(border: Border.all(color: tokens.line2)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(c.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            StatusChip.forIntegrationStatus(c.status),
                          ],
                        ),
                        Text(
                          c.lastSyncAt != null ? 'Last run: ${c.lastSyncAt}' : 'Never run yet',
                          style: TextStyle(fontSize: 11, color: tokens.ink2),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.rows});

  final List<CaptureBatchSummary> rows;

  @override
  Widget build(BuildContext context) {
    final totalBatches = rows.fold<int>(0, (sum, r) => sum + r.batches);
    final totalPages = rows.fold<int>(0, (sum, r) => sum + r.totalPages);
    final totalDocuments = rows.fold<int>(0, (sum, r) => sum + r.totalDocuments);
    final avgSuccess = rows.isEmpty ? 0 : rows.fold<double>(0, (sum, r) => sum + r.avgSuccessRate) / rows.length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(width: 180, child: KpiCard(label: 'Total batches', value: '$totalBatches', sub: 'Across all sources')),
        SizedBox(width: 180, child: KpiCard(label: 'Total pages', value: '$totalPages')),
        SizedBox(width: 180, child: KpiCard(label: 'Total documents', value: '$totalDocuments')),
        SizedBox(width: 180, child: KpiCard(label: 'Avg. success rate', value: '${avgSuccess.toStringAsFixed(1)}%')),
      ],
    );
  }
}
