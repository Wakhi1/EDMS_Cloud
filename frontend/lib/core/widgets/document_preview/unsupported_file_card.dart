import 'package:flutter/material.dart';

import '../../theme/pspf_tokens.dart';

/// Professional fallback for a file type with no in-app preview (legacy
/// binary .doc/.xls, or anything else) — a file-type card with its icon,
/// name, and size, rather than a bare "not supported" line. [onDownload]
/// is optional so this can also render inside contexts that already show
/// their own download action elsewhere.
class UnsupportedFileCard extends StatelessWidget {
  const UnsupportedFileCard({
    super.key,
    required this.fileName,
    this.contentType,
    this.sizeBytes,
    this.onDownload,
  });

  final String? fileName;
  final String? contentType;
  final int? sizeBytes;
  final VoidCallback? onDownload;

  IconData get _icon {
    final name = (fileName ?? '').toLowerCase();
    final type = contentType ?? '';
    if (name.endsWith('.doc') || name.endsWith('.docx') || type.contains('word')) return Icons.description_outlined;
    if (name.endsWith('.xls') || name.endsWith('.xlsx') || type.contains('excel') || type.contains('spreadsheet')) {
      return Icons.table_chart_outlined;
    }
    if (name.endsWith('.ppt') || name.endsWith('.pptx') || type.contains('presentation')) return Icons.slideshow_outlined;
    if (name.endsWith('.zip') || name.endsWith('.rar')) return Icons.folder_zip_outlined;
    return Icons.insert_drive_file_outlined;
  }

  String get _sizeLabel {
    final bytes = sizeBytes;
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: tokens.surf2, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(_icon, size: 28, color: tokens.accD),
          ),
          const SizedBox(height: 14),
          if (fileName != null)
            Text(fileName!, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          if (_sizeLabel.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(_sizeLabel, style: TextStyle(fontSize: 12, color: tokens.ink2)),
          ],
          const SizedBox(height: 10),
          Text(
            'Preview isn\'t available for this file type.',
            style: TextStyle(color: tokens.ink2),
            textAlign: TextAlign.center,
          ),
          if (onDownload != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download'),
            ),
          ],
        ],
      ),
    );
  }
}
