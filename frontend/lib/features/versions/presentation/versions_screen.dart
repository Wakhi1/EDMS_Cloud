import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/document_version_row.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/utils/mime_type.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../document_viewer/providers/viewer_providers.dart';
import '../providers/versions_providers.dart';

/// Bare `/versions` (no id) — reached via the nav item, which has no
/// document context. Versions are always document-scoped; point the user
/// at where to actually get there.
class VersionsEmptyScreen extends StatelessWidget {
  const VersionsEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        message: 'Version history is per-record. Open a record from Repository or Search, '
            'then choose "Version history" in its detail panel.',
        action: OutlinedButton(
          onPressed: () => context.go(RoutePaths.repository),
          child: const Text('Go to Repository'),
        ),
      ),
    );
  }
}

class VersionsScreen extends ConsumerWidget {
  const VersionsScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(documentId);
    if (id == null) {
      return const EmptyState(message: 'Invalid record reference.');
    }
    final detailAsync = ref.watch(documentDetailProvider(id));
    final versionsAsync = ref.watch(documentVersionsProvider(id));

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: detailAsync.when(
                  loading: () => Text('Records / Version history', style: Theme.of(context).textTheme.titleMedium),
                  error: (_, _) => Text('Records / Version history', style: Theme.of(context).textTheme.titleMedium),
                  data: (doc) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Records / Version history', style: Theme.of(context).textTheme.labelSmall),
                      Text(doc.title, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
              _UploadVersionButton(documentId: id),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => context.go(RoutePaths.viewerFor('$id')),
                child: const Text('Back to record'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: versionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: error is ApiException ? error.message : '$error',
                onRetry: () => ref.invalidate(documentVersionsProvider(id)),
              ),
              data: (versions) {
                if (versions.isEmpty) return const EmptyState(message: 'No versions found.');
                final sorted = [...versions]..sort((a, b) => b.versionNo.compareTo(a.versionNo));
                return ListView.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _VersionRow(documentId: id, version: sorted[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadVersionButton extends ConsumerStatefulWidget {
  const _UploadVersionButton({required this.documentId});

  final int documentId;

  @override
  ConsumerState<_UploadVersionButton> createState() => _UploadVersionButtonState();
}

class _UploadVersionButtonState extends ConsumerState<_UploadVersionButton> {
  bool _uploading = false;

  Future<void> _upload() async {
    final picked = await FilePicker.pickFile();
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      await ref.read(versionsApiProvider).uploadNewVersion(
            documentId: widget.documentId,
            fileBytes: bytes,
            fileName: picked.name,
            mimeType: mimeTypeForExtension(extensionOf(picked.name)),
          );
      ref.invalidate(documentVersionsProvider(widget.documentId));
      ref.invalidate(documentDetailProvider(widget.documentId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New version uploaded.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _uploading ? null : _upload,
      child: _uploading
          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text('Upload new version'),
    );
  }
}

class _VersionRow extends ConsumerStatefulWidget {
  const _VersionRow({required this.documentId, required this.version});

  final int documentId;
  final DocumentVersionRow version;

  @override
  ConsumerState<_VersionRow> createState() => _VersionRowState();
}

class _VersionRowState extends ConsumerState<_VersionRow> {
  bool _restoring = false;

  Future<void> _restore() async {
    final v = widget.version;
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Restore v${v.versionNo} as the current version?',
      body: 'Nothing is overwritten — restoring writes a new "current" pointer to this version\'s content.',
      rows: [('Version', 'v${v.versionNo}'), ('File', v.fileName)],
      okLabel: 'Restore',
    );
    if (confirmed == null) return;

    setState(() => _restoring = true);
    try {
      await ref.read(versionsApiProvider).restore(v.id);
      ref.invalidate(documentVersionsProvider(widget.documentId));
      ref.invalidate(documentDetailProvider(widget.documentId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('v${v.versionNo} promoted to current.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final v = widget.version;
    final sizeKb = v.sizeBytes != null ? '${(v.sizeBytes! / 1024).toStringAsFixed(1)} KB' : '—';

    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            color: v.isCurrent ? tokens.acc : tokens.surf3,
            child: Text('v${v.versionNo}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: v.isCurrent ? Colors.white : tokens.ink2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(v.fileName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    if (v.isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(border: Border.all(color: tokens.ok)),
                        child: Text('CURRENT', style: TextStyle(fontSize: 10, color: tokens.ok)),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${v.createdAt?.split("T").first ?? "—"} · ${v.createdBy ?? "—"} · $sizeKb',
                  style: TextStyle(fontSize: 11.5, color: tokens.ink2),
                ),
              ],
            ),
          ),
          if (v.isCurrent)
            OutlinedButton(
              onPressed: () => context.go(RoutePaths.viewerFor('${widget.documentId}')),
              child: const Text('View'),
            ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: (_restoring || v.isCurrent) ? null : _restore,
            child: _restoring
                ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Restore'),
          ),
        ],
      ),
    );
  }
}
