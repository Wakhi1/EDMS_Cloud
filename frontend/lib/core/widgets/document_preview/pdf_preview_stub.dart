import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Non-web fallback — inline PDF rendering relies on the browser's native
/// viewer via an iframe, which only exists on the web target.
class PdfPreview extends StatelessWidget {
  const PdfPreview({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('PDF preview is only available on web.'));
  }
}
