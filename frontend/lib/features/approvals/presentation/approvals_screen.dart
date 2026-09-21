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
import '../../../core/widgets/result_dialog.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../settings/providers/signature_providers.dart';
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
    if (item.requiresSignature) {
      final result = await showDialog<({String comment, String page, String position})>(
        context: context,
        builder: (_) => _SignatureApproveDialog(item: item),
      );
      if (result == null) return;
      setState(() => _busy = true);
      try {
        await ref.read(approvalsApiProvider).approve(
              item.approvalId,
              comment: result.comment.isEmpty ? null : result.comment,
              signaturePlacement: (page: result.page, position: result.position),
            );
        _refresh();
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

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
      if (mounted) await ResultDialog.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final item = widget.item;
    // Defaults to "assume true" while the check is loading, so the button
    // doesn't flash disabled before mySignatureMetaProvider resolves — only
    // a confirmed-false result actually blocks Approve.
    final hasSignature = ref.watch(mySignatureMetaProvider).valueOrNull?.hasSignature;

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
              if (item.requiresSignature)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(border: Border.all(color: tokens.acc)),
                  child: Text('Requires signature', style: TextStyle(fontSize: 11, color: tokens.acc)),
                ),
            ],
          ),
          if (item.requiresSignature && !(hasSignature ?? true)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: tokens.surf2, border: Border(left: BorderSide(color: tokens.warn, width: 3))),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'This step requires your signature. Save one in Settings before approving.',
                      style: TextStyle(fontSize: 12, color: tokens.ink2),
                    ),
                  ),
                  TextButton(onPressed: () => context.go(RoutePaths.settings), child: const Text('Go to Settings')),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: _busy || (item.requiresSignature && !(hasSignature ?? true)) ? null : _approve,
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

const _kSignaturePages = <(String, String)>[('last', 'Last page'), ('first', 'First page')];
const _kSignaturePositions = <(String, String)>[
  ('bottom-right', 'Bottom right'),
  ('bottom-left', 'Bottom left'),
  ('bottom-center', 'Bottom center'),
  ('top-right', 'Top right'),
  ('top-left', 'Top left'),
];

/// Approve confirmation for a requires_signature step — shows a preview of
/// the saved signature that's about to be attached (backend snapshots it
/// into workflow_approval_signatures the moment this is confirmed) rather
/// than silently applying it, since a digital signature is significant
/// enough to warrant seeing exactly what's being stamped before it happens.
/// The page/position pickers below always ship with the approval; the
/// server only actually stamps the document when an admin has turned that
/// on in Settings (system_settings.embed_approval_signatures) — otherwise
/// it's a harmless no-op, same as picking a watermark that isn't active.
/// Returns (comment, page, position) on confirm, null on cancel.
class _SignatureApproveDialog extends ConsumerStatefulWidget {
  const _SignatureApproveDialog({required this.item});

  final ApprovalItem item;

  @override
  ConsumerState<_SignatureApproveDialog> createState() => _SignatureApproveDialogState();
}

class _SignatureApproveDialogState extends ConsumerState<_SignatureApproveDialog> {
  final _controller = TextEditingController();
  String _page = 'last';
  String _position = 'bottom-right';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final item = widget.item;
    final signatureBytes = ref.watch(mySignatureImageBytesProvider).valueOrNull;

    return AlertDialog(
      title: Text('Authorise ${item.recordNo}?'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.title} — your authorisation is recorded against this record and advances it to the next step.',
                style: textTheme.bodyMedium?.copyWith(color: tokens.ink2),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 130, child: Text('STEP', style: textTheme.labelSmall)),
                    Expanded(child: Text(item.stepName, style: textTheme.bodyMedium)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('YOUR SIGNATURE', style: textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(
                'This will be attached to the approval record.',
                style: textTheme.bodySmall?.copyWith(color: tokens.ink2),
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                width: 200,
                decoration: BoxDecoration(border: Border.all(color: tokens.line), color: Colors.grey.shade100),
                alignment: Alignment.center,
                child: signatureBytes != null
                    ? Image.memory(signatureBytes, fit: BoxFit.contain)
                    : const CircularProgressIndicator(),
              ),
              const SizedBox(height: 12),
              Text('WHERE TO STAMP IT ON THE DOCUMENT', style: textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(
                'Only applied if an administrator has turned on document signature embedding.',
                style: textTheme.bodySmall?.copyWith(color: tokens.ink2),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _page,
                      isDense: true,
                      decoration: const InputDecoration(labelText: 'Page', isDense: true),
                      items: [for (final p in _kSignaturePages) DropdownMenuItem(value: p.$1, child: Text(p.$2))],
                      onChanged: (v) => setState(() => _page = v ?? _page),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _position,
                      isDense: true,
                      decoration: const InputDecoration(labelText: 'Position', isDense: true),
                      items: [for (final p in _kSignaturePositions) DropdownMenuItem(value: p.$1, child: Text(p.$2))],
                      onChanged: (v) => setState(() => _position = v ?? _position),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('COMMENT (OPTIONAL)', style: textTheme.labelMedium),
              const SizedBox(height: 4),
              TextField(controller: _controller, autofocus: true),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop((comment: _controller.text, page: _page, position: _position)),
          child: const Text('Authorise'),
        ),
      ],
    );
  }
}
