import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/reports_providers.dart';

const _kFormats = <(String, String)>[('pdf', 'PDF'), ('xlsx', 'Excel'), ('csv', 'CSV')];

/// Format + "include my signature" picker for the Reports export button.
/// Pops `null` on cancel, or `(format, includeSignature)` on Export — the
/// signature checkbox only ever resolves true for PDF and only when the
/// signed-in user actually has one saved (Settings -> My Signature).
class ExportReportDialog extends ConsumerStatefulWidget {
  const ExportReportDialog({super.key});

  @override
  ConsumerState<ExportReportDialog> createState() => _ExportReportDialogState();
}

class _ExportReportDialogState extends ConsumerState<ExportReportDialog> {
  String _format = 'pdf';
  bool _includeSignature = false;

  @override
  Widget build(BuildContext context) {
    final hasSignature = ref.watch(hasSavedSignatureProvider).valueOrNull ?? false;
    final signatureAvailable = _format == 'pdf' && hasSignature;

    return AlertDialog(
      title: const Text('Export report'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final f in _kFormats)
            RadioListTile<String>(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: f.$1,
              // ignore: deprecated_member_use
              groupValue: _format,
              title: Text(f.$2),
              // ignore: deprecated_member_use
              onChanged: (v) => setState(() => _format = v!),
            ),
          const Divider(height: 20),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: _includeSignature && signatureAvailable,
            onChanged: signatureAvailable ? (v) => setState(() => _includeSignature = v ?? false) : null,
            title: const Text('Include my signature'),
            subtitle: Text(
              _format != 'pdf'
                  ? 'Only available for PDF exports.'
                  : hasSignature
                      ? 'Appends your saved signature at the end of the report.'
                      : 'Save a signature in Settings → My Signature first.',
              style: const TextStyle(fontSize: 11.5),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop((format: _format, includeSignature: _includeSignature && signatureAvailable)),
          child: const Text('Export'),
        ),
      ],
    );
  }
}
