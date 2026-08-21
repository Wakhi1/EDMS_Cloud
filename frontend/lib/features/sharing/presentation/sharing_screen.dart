import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/document_record.dart';
import '../../../core/models/share_link.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/sharing_providers.dart';

final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

const _kExpiryOptions = <(String, int)>[
  ('1 hour', 1),
  ('24 hours', 24),
  ('7 days', 24 * 7),
  ('30 days', 24 * 30),
  ('90 days', 24 * 90),
];

/// Real Sharing & Links screen — expiring, revocable public links for a
/// document's current version, backed by backend/routes/sharing.routes.js
/// (see database/pspf_edms_schema.sql's document_share_links). A recipient
/// opens the link (features/sharing/presentation/share_view_screen.dart, the
/// public /s/:token route) with no EDMS account of their own.
class SharingScreen extends ConsumerWidget {
  const SharingScreen({super.key});

  Future<void> _createShare(BuildContext context, WidgetRef ref) async {
    final picked = await showDialog<DocumentRecord>(context: context, builder: (_) => const _PickDocumentDialog());
    if (picked == null || !context.mounted) return;

    final expiry = await showDialog<int>(context: context, builder: (_) => _PickExpiryDialog(doc: picked));
    if (expiry == null) return;

    try {
      final result = await ref.read(sharingApiProvider).create(documentId: picked.id, expiresInHours: expiry);
      ref.invalidate(shareLinksProvider);
      if (context.mounted) await _showLinkDialog(context, result.token);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showLinkDialog(BuildContext context, String token) {
    // Share the app's own /s/:token landing page, not the raw content URL —
    // the recipient sees record info and an explicit download action there.
    final shareUrl = '${Uri.base.origin}${Uri.base.path}#/s/$token';
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Share link created'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Anyone with this link can view and download this record until it expires or is revoked.'),
              const SizedBox(height: 12),
              SelectableText(shareUrl, style: const TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareUrl));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied.')));
            },
            child: const Text('Copy link'),
          ),
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
        ],
      ),
    );
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref, ShareLink link) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Revoke this link?',
      body: '"${link.title}" — anyone with this link will immediately lose access.',
      okLabel: 'Revoke',
      danger: true,
    );
    if (confirmed == null) return;

    try {
      await ref.read(sharingApiProvider).revoke(link.id);
      ref.invalidate(shareLinksProvider);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(shareLinksProvider);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Records / Sharing & Links', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _createShare(context, ref),
                icon: const Icon(Icons.add_link, size: 16),
                label: const Text('Share a record'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Expiring, revocable links — a recipient needs no EDMS account to view or download.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.tokens.ink2),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: linksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: error is ApiException ? error.message : '$error',
                onRetry: () => ref.invalidate(shareLinksProvider),
              ),
              data: (links) => links.isEmpty
                  ? const EmptyState(message: 'No share links yet. Use "Share a record" to create one.')
                  : _LinksList(links: links, onRevoke: (l) => _revoke(context, ref, l)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinksList extends StatelessWidget {
  const _LinksList({required this.links, required this.onRevoke});

  final List<ShareLink> links;
  final void Function(ShareLink) onRevoke;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: tokens.surf2,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Record')),
                Expanded(flex: 2, child: Text('Status')),
                Expanded(flex: 2, child: Text('Expires')),
                Expanded(flex: 1, child: Text('Views')),
                SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: links.length,
              itemBuilder: (context, i) {
                final l = links[i];
                final (label, color) = switch ((l.isRevoked, l.isExpired)) {
                  (true, _) => ('Revoked', tokens.bad),
                  (_, true) => ('Expired', tokens.ink3),
                  _ => ('Active', tokens.ok),
                };
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.line))),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.title, overflow: TextOverflow.ellipsis),
                            Text(l.recordNo, style: TextStyle(fontSize: 11, color: tokens.ink2)),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text(label, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: Text(_dateTimeFormat.format(DateTime.parse(l.expiresAt).toLocal()), style: const TextStyle(fontSize: 12))),
                      Expanded(flex: 1, child: Text('${l.accessCount}', style: const TextStyle(fontSize: 12))),
                      SizedBox(
                        width: 40,
                        child: l.isActive
                            ? IconButton(
                                tooltip: 'Revoke',
                                icon: Icon(Icons.link_off, size: 17, color: tokens.bad),
                                padding: EdgeInsets.zero,
                                onPressed: () => onRevoke(l),
                              )
                            : null,
                      ),
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

class _PickDocumentDialog extends ConsumerStatefulWidget {
  const _PickDocumentDialog();

  @override
  ConsumerState<_PickDocumentDialog> createState() => _PickDocumentDialogState();
}

class _PickDocumentDialogState extends ConsumerState<_PickDocumentDialog> {
  final _controller = TextEditingController();
  List<DocumentRecord>? _results;
  bool _searching = false;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await ref.read(documentsApiProvider).search(q: q.trim());
      if (mounted) setState(() => _results = results);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AlertDialog(
      title: const Text('Choose a record to share'),
      content: SizedBox(
        width: 420,
        height: 360,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(isDense: true, hintText: 'Search by title, record no., member…', prefixIcon: Icon(Icons.search, size: 18)),
              onSubmitted: _search,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _searching
                  ? const Center(child: CircularProgressIndicator())
                  : _results == null
                      ? Center(child: Text('Search for a record above.', style: TextStyle(color: tokens.ink2, fontSize: 12.5)))
                      : _results!.isEmpty
                          ? const EmptyState(message: 'No records match.')
                          : ListView.separated(
                              itemCount: _results!.length,
                              separatorBuilder: (_, _) => Divider(height: 1, color: tokens.line),
                              itemBuilder: (context, i) {
                                final d = _results![i];
                                return ListTile(
                                  dense: true,
                                  title: Text(d.title, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(d.recordNo, style: const TextStyle(fontSize: 11)),
                                  onTap: () => Navigator.of(context).pop(d),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))],
    );
  }
}

class _PickExpiryDialog extends StatefulWidget {
  const _PickExpiryDialog({required this.doc});

  final DocumentRecord doc;

  @override
  State<_PickExpiryDialog> createState() => _PickExpiryDialogState();
}

class _PickExpiryDialogState extends State<_PickExpiryDialog> {
  int _hours = 24 * 7;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Share "${widget.doc.title}"'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Link expires in'),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              initialValue: _hours,
              isExpanded: true,
              items: [for (final o in _kExpiryOptions) DropdownMenuItem(value: o.$2, child: Text(o.$1))],
              onChanged: (v) => setState(() => _hours = v ?? _hours),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(context).pop(_hours), child: const Text('Create link')),
      ],
    );
  }
}
