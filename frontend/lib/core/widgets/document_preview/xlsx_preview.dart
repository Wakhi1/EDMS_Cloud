import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:microsoft_viewer/microsoft_viewer.dart';

/// Excel spreadsheet (.xlsx) preview — offline rendering, no bytes leave
/// the device. Explicitly described upstream as basic ("minimum
/// formatting" support) rather than pixel-perfect — accepted tradeoff for
/// in-app preview without a server-side conversion pipeline or sending
/// confidential records to a third-party viewer (Office Online / Google
/// Docs Viewer). Legacy binary .xls isn't handled — see
/// UnsupportedFileCard for that case.
class XlsxPreview extends StatelessWidget {
  const XlsxPreview({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    // fixedHeight: true — the package's own doc comment/source shows this
    // self-wraps in a Column+Expanded, so it only needs a bounded height
    // from its parent; fixedHeight: false returns a bare Expanded that
    // requires the parent itself to already be a Row/Column, which
    // viewer_screen.dart's fixed-height Container isn't.
    return MicrosoftViewer(bytes, true);
  }
}
