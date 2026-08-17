import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/document_record.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/utils/file_saver/file_saver.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/document_preview/pdf_preview.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../providers/viewer_providers.dart';
import 'extracted_text_panel.dart';
import 'route_for_approval_dialog.dart';

class ViewerScreen extends ConsumerWidget {
  const ViewerScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(documentId);
    if (id == null) {
      return const EmptyState(message: 'Invalid record reference.');
    }
    final detailAsync = ref.watch(documentDetailProvider(id));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: error is ApiException ? error.message : '$error',
        onRetry: () => ref.invalidate(documentDetailProvider(id)),
      ),
      data: (doc) => _ViewerBody(doc: doc),
    );
  }
}

class _ViewerBody extends ConsumerStatefulWidget {
  const _ViewerBody({required this.doc});

  final DocumentRecord doc;

  @override
  ConsumerState<_ViewerBody> createState() => _ViewerBodyState();
}

class _ViewerBodyState extends ConsumerState<_ViewerBody> {
  bool _downloading = false;
  bool _routing = false;
  bool _declaring = false;

  bool _previewLoading = false;
  Uint8List? _previewBytes;
  String? _previewContentType;
  String? _previewError;

  @override
  void initState() {
    super.initState();
    if (widget.doc.classification != 'confidential') {
      _loadPreview();
    }
  }

  Future<void> _loadPreview({String? reason}) async {
    setState(() {
      _previewLoading = true;
      _previewError = null;
    });
    try {
      final content = await ref.read(documentsApiProvider).content(widget.doc.id, reason: reason);
      if (!mounted) return;
      setState(() {
        _previewBytes = Uint8List.fromList(content.bytes);
        _previewContentType = content.contentType;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _previewError = e.message);
    } finally {
      if (mounted) setState(() => _previewLoading = false);
    }
  }

  Future<void> _revealConfidentialPreview() async {
    final doc = widget.doc;
    final reason = await ConfirmDialog.show(
      context,
      title: 'View ${doc.recordNo}',
      body: 'Confidential records require a stated reason to open, written to the audit trail.',
      fieldLabel: 'Reason for access',
      okLabel: 'View record',
    );
    if (reason == null) return;
    await _loadPreview(reason: reason);
  }

  Future<void> _declareFinal() async {
    final doc = widget.doc;
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Declare ${doc.recordNo} final?',
      body: 'This starts the retention clock — the record moves to "declared final" and its retention due date '
          'is computed from its retention class. This cannot be undone from the Viewer.',
      rows: [('Record', doc.title), ('Classification', doc.classification)],
      okLabel: 'Declare final',
      danger: true,
    );
    if (confirmed == null) return;

    setState(() => _declaring = true);
    try {
      await ref.read(documentsApiProvider).declareFinal(doc.id);
      ref.invalidate(documentDetailProvider(doc.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record declared final — retention clock started.')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _declaring = false);
    }
  }

  Future<void> _routeForApproval() async {
    final workflowId = await showDialog<int>(
      context: context,
      builder: (_) => const RouteForApprovalDialog(),
    );
    if (workflowId == null) return;

    setState(() => _routing = true);
    try {
      await ref.read(workflowApiProvider).startInstance(workflowId: workflowId, documentId: widget.doc.id);
      ref.invalidate(documentDetailProvider(widget.doc.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Routed for approval.')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _routing = false);
    }
  }

  Future<void> _download() async {
    final doc = widget.doc;
    String? reason;
    if (doc.classification == 'confidential') {
      reason = await ConfirmDialog.show(
        context,
        title: 'Download a copy of ${doc.recordNo}',
        body: 'Confidential records require a stated reason to open, written to the audit trail.',
        fieldLabel: 'Reason for access',
        okLabel: 'Download',
      );
      if (reason == null) return; // cancelled
    }

    setState(() => _downloading = true);
    try {
      final content = await ref.read(documentsApiProvider).content(doc.id, reason: reason);
      final fileName = content.fileName ?? '${doc.recordNo}.pdf';
      await saveBytes(bytes: content.bytes, fileName: fileName, mimeType: content.contentType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded $fileName')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final showPanelBeside = width >= 900;

    final panel = Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(doc.title, style: textTheme.titleSmall),
          Text(doc.recordNo, style: TextStyle(fontSize: 12, color: tokens.ink2)),
          const SizedBox(height: 10),
          StatusChip.forDocumentStatus(doc.status),
          const SizedBox(height: 10),
          for (final (k, v) in <(String, String)>[
            ('Type', doc.documentType ?? '—'),
            ('Department', doc.department ?? '—'),
            ('Custodian', doc.ownerName ?? '—'),
            ('Version', doc.currentVersionNo != null ? 'v${doc.currentVersionNo}' : '—'),
            ('Classification', doc.classification),
            ('File plan', doc.folderPath ?? '—'),
            ('Member', doc.memberName ?? doc.memberNumber ?? '—'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 96, child: Text(k.toUpperCase(), style: textTheme.labelSmall)),
                  Expanded(child: Text(v, style: const TextStyle(fontSize: 12.5))),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _downloading ? null : _download,
              child: _downloading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Download'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _routing ? null : _routeForApproval,
              child: _routing
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Route for approval'),
            ),
          ),
          if (doc.status == 'approved') ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _declaring ? null : _declareFinal,
                child: _declaring
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Declare final'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go(RoutePaths.versionsFor('${doc.id}')),
              child: const Text('Version history'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/permissions/document/${doc.id}'),
              child: const Text('Manage access'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go(RoutePaths.repository),
              child: const Text('Back to repository'),
            ),
          ),
        ],
      ),
    );

    Widget messageBox({required IconData icon, required String message, Widget? action}) {
      return Container(
        decoration: BoxDecoration(border: Border.all(color: tokens.line)),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: tokens.ink3),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: tokens.ink2), textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 12), action],
          ],
        ),
      );
    }

    final Widget renderedPreview;
    if (doc.classification == 'confidential' && _previewBytes == null && !_previewLoading) {
      renderedPreview = SizedBox(
        height: 260,
        child: messageBox(
          icon: Icons.lock_outline,
          message: 'This is a confidential record. Viewing it requires a stated reason, written to the audit trail.',
          action: ElevatedButton(onPressed: _revealConfidentialPreview, child: const Text('View record')),
        ),
      );
    } else if (_previewLoading) {
      renderedPreview = const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()));
    } else if (_previewError != null) {
      renderedPreview = SizedBox(
        height: 260,
        child: messageBox(
          icon: Icons.error_outline,
          message: _previewError!,
          action: OutlinedButton(onPressed: () => _loadPreview(), child: const Text('Retry')),
        ),
      );
    } else if (_previewBytes case final bytes?) {
      final contentType = _previewContentType ?? '';
      if (contentType.startsWith('image/')) {
        renderedPreview = Container(
          height: 520,
          decoration: BoxDecoration(border: Border.all(color: tokens.line)),
          child: InteractiveViewer(child: Center(child: Image.memory(bytes, fit: BoxFit.contain))),
        );
      } else if (contentType == 'application/pdf') {
        renderedPreview = Container(
          height: 640,
          decoration: BoxDecoration(border: Border.all(color: tokens.line)),
          child: PdfPreview(bytes: bytes),
        );
      } else {
        renderedPreview = SizedBox(
          height: 260,
          child: messageBox(
            icon: Icons.description_outlined,
            message: 'Preview isn\'t supported for this file type — use Download to open the file.',
          ),
        );
      }
    } else {
      renderedPreview = SizedBox(
        height: 260,
        child: messageBox(icon: Icons.description_outlined, message: 'Preview not available.'),
      );
    }

    final preview = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        renderedPreview,
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: ExtractedTextPanel(documentId: doc.id),
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: showPanelBeside
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: preview),
                const SizedBox(width: 16),
                SizedBox(width: 280, child: panel),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [panel, const SizedBox(height: 16), preview],
            ),
    );
  }
}
