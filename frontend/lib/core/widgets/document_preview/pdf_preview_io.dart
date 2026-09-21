import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pdfx/pdfx.dart';
import 'package:printing/printing.dart';

import '../../theme/pspf_tokens.dart';

/// Non-web PDF rendering (Android/iOS/Windows/macOS/Linux). Split by
/// platform rather than one library for all of them:
///  - Android/iOS: flutter_pdfview, wrapping each platform's own native
///    viewer (AndroidPdfViewer / PDFKit) — full-fidelity, actively
///    maintained, and the standard choice for those platforms.
///  - Windows (and any other desktop platform flutter_pdfview doesn't
///    cover): a custom viewer built directly on pdfx's page-rendering API
///    (not its ready-made PdfView/PdfViewPinch widgets — PdfViewPinch
///    throws UnimplementedError on Windows, confirmed live: "PdfViewPinch
///    not supported in Windows, usage PdfView instead"; PdfView works but
///    has no toolbar, 2-page spread, or print). This gives Windows a
///    proper toolbar (paging, zoom, 1/2-page view, print) that neither
///    ready-made pdfx widget provides on its own. pdfx has no PDF outline/
///    bookmark API at all (confirmed: zero matches for "outline" or
///    "bookmark" anywhere in its source) — a table-of-contents panel
///    genuinely isn't buildable on this library without forking it.
class PdfPreview extends StatelessWidget {
  const PdfPreview({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return PDFView(pdfData: bytes, fitPolicy: FitPolicy.BOTH);
    }
    return _PdfxProfessionalViewer(bytes: bytes);
  }
}

class _PdfxProfessionalViewer extends StatefulWidget {
  const _PdfxProfessionalViewer({required this.bytes});

  final Uint8List bytes;

  @override
  State<_PdfxProfessionalViewer> createState() => _PdfxProfessionalViewerState();
}

class _PdfxProfessionalViewerState extends State<_PdfxProfessionalViewer> {
  PdfDocument? _document;
  String? _error;
  int _page = 1;
  bool _twoPageView = false;
  final _pageFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final doc = await PdfDocument.openData(widget.bytes);
      if (!mounted) {
        await doc.close();
        return;
      }
      setState(() => _document = doc);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _document?.close();
    _pageFieldController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    final doc = _document;
    if (doc == null) return;
    setState(() => _page = page.clamp(1, doc.pagesCount));
  }

  void _submitPageField() {
    final n = int.tryParse(_pageFieldController.text);
    if (n != null) _goTo(n);
    _pageFieldController.clear();
  }

  Future<void> _print() async {
    await Printing.layoutPdf(onLayout: (_) async => widget.bytes);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Couldn\'t open this PDF: $_error', style: TextStyle(color: tokens.bad), textAlign: TextAlign.center),
        ),
      );
    }
    final doc = _document;
    if (doc == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final step = _twoPageView ? 2 : 1;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: tokens.surf2, border: Border(bottom: BorderSide(color: tokens.line))),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous page',
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: _page > 1 ? () => _goTo(_page - step) : null,
              ),
              SizedBox(
                width: 40,
                child: TextField(
                  controller: _pageFieldController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '$_page',
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  onSubmitted: (_) => _submitPageField(),
                ),
              ),
              Text(' / ${doc.pagesCount}', style: TextStyle(color: tokens.ink2, fontSize: 12.5)),
              IconButton(
                tooltip: 'Next page',
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: _page + step <= doc.pagesCount ? () => _goTo(_page + step) : null,
              ),
              const Spacer(),
              if (doc.pagesCount > 1)
                IconButton(
                  tooltip: _twoPageView ? 'Single page view' : 'Two-page view',
                  icon: Icon(_twoPageView ? Icons.filter_1_outlined : Icons.filter_2_outlined, size: 20),
                  onPressed: () => setState(() => _twoPageView = !_twoPageView),
                ),
              IconButton(
                tooltip: 'Print',
                icon: const Icon(Icons.print_outlined, size: 20),
                onPressed: _print,
              ),
            ],
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            maxScale: 4,
            child: Center(
              child: _twoPageView
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PageImage(document: doc, pageNumber: _page),
                        if (_page + 1 <= doc.pagesCount) _PageImage(document: doc, pageNumber: _page + 1),
                      ],
                    )
                  : _PageImage(document: doc, pageNumber: _page),
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders one page via pdfx's lower-level PdfDocument.getPage/PdfPage.render
/// (not the ready-made PdfView widget, which only shows one page per
/// PhotoViewGallery item and can't be laid out side-by-side for a 2-page
/// spread) — closes the native page handle once rendered, same as pdfx's
/// own internal PdfPageImageProvider does.
class _PageImage extends StatefulWidget {
  const _PageImage({required this.document, required this.pageNumber});

  final PdfDocument document;
  final int pageNumber;

  @override
  State<_PageImage> createState() => _PageImageState();
}

class _PageImageState extends State<_PageImage> {
  Uint8List? _bytes;
  double _aspectRatio = 0.75;

  @override
  void initState() {
    super.initState();
    _render();
  }

  @override
  void didUpdateWidget(covariant _PageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber || oldWidget.document != widget.document) {
      _bytes = null;
      _render();
    }
  }

  Future<void> _render() async {
    final page = await widget.document.getPage(widget.pageNumber);
    // Render at 2x the page's own point size for a crisp result on
    // high-DPI displays without an excessive memory footprint.
    final image = await page.render(width: page.width * 2, height: page.height * 2);
    await page.close();
    if (!mounted || image == null) return;
    setState(() {
      _bytes = image.bytes;
      _aspectRatio = page.width / page.height;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) {
      return AspectRatio(
        aspectRatio: _aspectRatio,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Image.memory(bytes);
  }
}
