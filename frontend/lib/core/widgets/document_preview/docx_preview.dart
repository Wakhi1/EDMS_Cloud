import 'dart:typed_data';

import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'package:flutter/material.dart';

import '../../theme/pspf_tokens.dart';

/// Word document (.docx) preview — pure-Flutter native rendering, fully
/// offline (no bytes ever leave the device, unlike the common "send it to
/// Google Docs Viewer / Office Online" trick, which isn't acceptable for
/// this app's confidential records). Legacy binary .doc isn't handled —
/// see UnsupportedFileCard for that case, decided in viewer_screen.dart's
/// routing based on the exact content type.
class DocxPreview extends StatefulWidget {
  const DocxPreview({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<DocxPreview> createState() => _DocxPreviewState();
}

class _DocxPreviewState extends State<DocxPreview> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Couldn\'t render this document: $_error',
            style: TextStyle(color: context.tokens.bad),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return DocxView(
      bytes: widget.bytes,
      config: const DocxViewConfig(enableSearch: true),
      onError: (Object error) => setState(() => _error = '$error'),
    );
  }
}
