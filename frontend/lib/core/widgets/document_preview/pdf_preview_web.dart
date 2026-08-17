import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Renders a PDF inline via the browser's native viewer: the bytes are
/// wrapped in a Blob object URL and shown through an iframe, registered as
/// a platform view — there's no pure-Dart PDF renderer in the dependency
/// set, and the browser already does this well for free.
class PdfPreview extends StatefulWidget {
  const PdfPreview({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<PdfPreview> {
  late final String _viewType;
  late final String _blobUrl;

  @override
  void initState() {
    super.initState();
    final blob = web.Blob(
      [widget.bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    _blobUrl = web.URL.createObjectURL(blob);
    _viewType = 'pdf-preview-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return web.HTMLIFrameElement()
        ..src = _blobUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
    });
  }

  @override
  void dispose() {
    web.URL.revokeObjectURL(_blobUrl);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
