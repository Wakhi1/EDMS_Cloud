import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/approval_item.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../providers/approvals_providers.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(approvalsInboxProvider);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Work / Approvals inbox', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Expanded(
            child: inboxAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: error is ApiException ? error.message : '$error',
                onRetry: () => ref.invalidate(approvalsInboxProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(message: 'Inbox clear — every item routed to you has been actioned.');
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _ApprovalCard(item: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends ConsumerStatefulWidget {
  const _ApprovalCard({required this.item});

  final ApprovalItem item;

  @override
  ConsumerState<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends ConsumerState<_ApprovalCard> {
  bool _busy = false;

  void _refresh() {
    ref.invalidate(approvalsInboxProvider);
    ref.invalidate(dashboardApprovalsProvider);
  }

  Future<void> _approve() async {
    final item = widget.item;
    final comment = await ConfirmDialog.show(
      context,
      title: 'Authorise ${item.recordNo}?',
      body: '${item.title} — your authorisation is recorded against this record and advances it to the next step.',
      rows: [('Step', item.stepName), ('SLA', '${item.slaDays ?? '—'} working day(s)')],
      fieldLabel: 'Comment (optional)',
      okLabel: 'Authorise',
    );
    if (comment == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(approvalsApiProvider).approve(item.approvalId, comment: comment.isEmpty ? null : comment);
      _refresh();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final item = widget.item;
    final comment = await ConfirmDialog.show(
      context,
      title: 'Return ${item.recordNo}?',
      body: 'The record returns to the previous workflow step. Your reason is stored in the audit trail.',
      fieldLabel: 'Reason for return',
      okLabel: 'Return record',
      danger: true,
    );
    if (comment == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(approvalsApiProvider).reject(item.approvalId, comment: comment.isEmpty ? null : comment);
      _refresh();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final item = widget.item;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surf,
        border: Border.all(color: tokens.line),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, color: tokens.warn, margin: const EdgeInsets.only(bottom: 10)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: textTheme.titleSmall),
                    Text('${item.recordNo} · ${item.stepName}', style: TextStyle(fontSize: 12, color: tokens.ink2)),
                  ],
                ),
              ),
              if (item.escalatedAt != null)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: tokens.bad),
                  child: const Text('Escalated', style: TextStyle(fontSize: 11, color: Colors.white)),
                ),
              if (item.slaDays != null)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(border: Border.all(color: tokens.warn)),
                  child: Text('SLA ${item.slaDays}d', style: TextStyle(fontSize: 11, color: tokens.warn)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: _busy ? null : _approve,
                child: const Text('Approve'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _busy ? null : _reject,
                style: OutlinedButton.styleFrom(foregroundColor: tokens.bad, side: BorderSide(color: tokens.bad)),
                child: const Text('Return'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => context.go(RoutePaths.viewerFor('${item.documentId}')),
                child: const Text('Open document'),
              ),
              if (_busy) ...[
                const SizedBox(width: 12),
                const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
