import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/pspf_tokens.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../providers/capture_providers.dart';

class BatchDetailDialog extends ConsumerWidget {
  const BatchDetailDialog({super.key, required this.batchId});

  final int batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final detailAsync = ref.watch(captureBatchDetailProvider(batchId));

    return AlertDialog(
      title: Text('Batch — ${detailAsync.valueOrNull?.batch.batchNo ?? '#$batchId'}'),
      content: SizedBox(
        width: 480,
        height: 440,
        child: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error is ApiException ? error.message : '$error', style: TextStyle(color: tokens.bad))),
          data: (detail) {
            final batch = detail.batch;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    Text('Source: ${batch.source.replaceAll('_', ' ')}', style: TextStyle(fontSize: 12.5, color: tokens.ink2)),
                    Text('Started: ${batch.startedAt ?? '—'}', style: TextStyle(fontSize: 12.5, color: tokens.ink2)),
                    StatusChip(
                      batch.status.replaceAll('_', ' '),
                      tone: batch.status == 'completed' ? StatusTone.ok : (batch.status == 'failed' ? StatusTone.bad : StatusTone.warn),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${detail.items.where((i) => i.status == 'succeeded').length} succeeded / '
                  '${detail.items.where((i) => i.status == 'duplicate').length} duplicate / '
                  '${detail.items.where((i) => i.status == 'failed').length} failed',
                  style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                ),
                const Divider(height: 20),
                Expanded(
                  child: detail.items.isEmpty
                      ? Center(child: Text('No items.', style: TextStyle(color: tokens.ink2)))
                      : ListView.separated(
                          itemCount: detail.items.length,
                          separatorBuilder: (_, _) => Divider(height: 1, color: tokens.line),
                          itemBuilder: (context, i) {
                            final item = detail.items[i];
                            final (icon, color, subtitle) = switch (item.status) {
                              'succeeded' => (Icons.check_circle_outline, tokens.ok, item.recordNo ?? 'indexed'),
                              'duplicate' => (Icons.content_copy, tokens.warn, 'Duplicate of ${item.recordNo ?? 'an existing record'}'),
                              _ => (Icons.error_outline, tokens.bad, item.errorMessage ?? 'failed'),
                            };
                            return ListTile(
                              dense: true,
                              leading: Icon(icon, size: 18, color: color),
                              title: Text(item.sourceFileName, style: const TextStyle(fontSize: 12.5)),
                              subtitle: Text(subtitle, style: TextStyle(fontSize: 11.5, color: color)),
                              onTap: item.documentId == null
                                  ? null
                                  : () {
                                      Navigator.of(context).pop();
                                      context.go(RoutePaths.viewerFor('${item.documentId}'));
                                    },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}
