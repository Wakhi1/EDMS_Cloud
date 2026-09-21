import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../theme/pspf_tokens.dart';

/// Plain text (.txt) preview — no package needed, just decode and render
/// monospace in a scrollable, selectable box.
class TextPreview extends StatelessWidget {
  const TextPreview({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = latin1.decode(bytes);
    }
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SelectableText(text, style: TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: tokens.ink)),
      ),
    );
  }
}
