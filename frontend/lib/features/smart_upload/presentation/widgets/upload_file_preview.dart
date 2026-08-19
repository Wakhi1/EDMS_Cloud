import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/pspf_tokens.dart';
import '../../../../core/widgets/document_preview/pdf_preview.dart';

enum _PreviewKind { image, pdf, csv, docx, unsupported }

const _docxMime = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

_PreviewKind _kindFor(String mimeType, String fileName) {
  final dot = fileName.lastIndexOf('.');
  final ext = dot >= 0 ? fileName.substring(dot + 1).toLowerCase() : '';
  if (mimeType.startsWith('image/')) return _PreviewKind.image;
  if (mimeType == 'application/pdf') return _PreviewKind.pdf;
  if (mimeType == 'text/csv' || ext == 'csv') return _PreviewKind.csv;
  if (mimeType == _docxMime || ext == 'docx') return _PreviewKind.docx;
  return _PreviewKind.unsupported;
}

/// Small clickable thumbnail/icon shown on a Smart Upload row; tapping opens
/// a full preview dialog. Renders straight from the bytes already held in
/// the upload queue — no extra network round-trip for image/csv — and reuses
/// the extracted text already fetched by the ocr-preview call for docx,
/// since there's no lightweight way to render real Word formatting client-side.
class UploadFilePreviewThumb extends StatelessWidget {
  const UploadFilePreviewThumb({
    super.key,
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.extractedText,
    required this.extractedTextLoading,
  });

  final List<int> bytes;
  final String fileName;
  final String mimeType;
  final String? extractedText;
  final bool extractedTextLoading;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final kind = _kindFor(mimeType, fileName);
    final clickable = kind != _PreviewKind.unsupported;

    Widget thumb;
    switch (kind) {
      case _PreviewKind.image:
        thumb = ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Image.memory(
            Uint8List.fromList(bytes),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Icon(Icons.broken_image_outlined, size: 22, color: tokens.ink3),
          ),
        );
      case _PreviewKind.pdf:
        thumb = Icon(Icons.picture_as_pdf_outlined, size: 24, color: tokens.ink2);
      case _PreviewKind.csv:
        thumb = Icon(Icons.table_chart_outlined, size: 24, color: tokens.ink2);
      case _PreviewKind.docx:
        thumb = Icon(Icons.description_outlined, size: 24, color: tokens.ink2);
      case _PreviewKind.unsupported:
        thumb = Icon(Icons.insert_drive_file_outlined, size: 24, color: tokens.ink3);
    }

    return Tooltip(
      message: clickable ? 'Preview $fileName' : 'Preview isn\'t available for this file type',
      child: InkWell(
        onTap: clickable ? () => _open(context, kind) : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf2),
          child: thumb,
        ),
      ),
    );
  }

  void _open(BuildContext context, _PreviewKind kind) {
    final typed = Uint8List.fromList(bytes);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: 720,
          height: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(fileName, style: Theme.of(dialogContext).textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(dialogContext).pop()),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Padding(padding: const EdgeInsets.all(12), child: _body(kind, typed)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(_PreviewKind kind, Uint8List typed) {
    switch (kind) {
      case _PreviewKind.image:
        return InteractiveViewer(child: Center(child: Image.memory(typed, fit: BoxFit.contain)));
      case _PreviewKind.pdf:
        return PdfPreview(bytes: typed);
      case _PreviewKind.csv:
        return _CsvTablePreview(bytes: typed);
      case _PreviewKind.docx:
        return _TextExtractPreview(loading: extractedTextLoading, text: extractedText);
      case _PreviewKind.unsupported:
        return const SizedBox.shrink();
    }
  }
}

/// Renders a CSV file as a scrollable table (first row treated as a header).
/// Parses client-side since the bytes are already in memory and CSV needs
/// no server round-trip — unlike docx, there's nothing to lose by not
/// reusing a backend extraction.
class _CsvTablePreview extends StatelessWidget {
  const _CsvTablePreview({required this.bytes});

  final Uint8List bytes;

  static const _maxRows = 200;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = latin1.decode(bytes);
    }
    final rows = _parseCsv(text).take(_maxRows).toList();
    if (rows.isEmpty) {
      return Center(child: Text('Empty file.', style: TextStyle(color: tokens.ink2)));
    }
    final columnCount = rows.fold<int>(0, (max, r) => r.length > max ? r.length : max);
    final header = rows.first;
    final body = rows.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rows.length >= _maxRows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Showing the first $_maxRows rows.', style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
          ),
        Expanded(
          child: Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowHeight: 34,
                  dataRowMinHeight: 26,
                  dataRowMaxHeight: 32,
                  columns: [
                    for (var c = 0; c < columnCount; c++)
                      DataColumn(
                        label: Text(
                          c < header.length ? header[c] : '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                  ],
                  rows: [
                    for (final row in body)
                      DataRow(
                        cells: [
                          for (var c = 0; c < columnCount; c++)
                            DataCell(Text(c < row.length ? row[c] : '', style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Minimal RFC-4180-ish CSV parser: quoted fields, embedded commas/newlines
/// inside quotes, and "" as an escaped quote. Good enough for a preview —
/// not a general-purpose CSV library dependency for one read-only table.
List<List<String>> _parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;
  while (i < text.length) {
    final ch = text[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        inQuotes = false;
        i++;
        continue;
      }
      field.write(ch);
      i++;
      continue;
    }
    if (ch == '"') {
      inQuotes = true;
      i++;
      continue;
    }
    if (ch == ',') {
      row.add(field.toString());
      field.clear();
      i++;
      continue;
    }
    if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = [];
      i++;
      continue;
    }
    field.write(ch);
    i++;
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
}

/// Docx preview fallback: shows the raw text mammoth already extracted
/// server-side for OCR/indexing (`row.extractedText`) rather than rendering
/// real Word formatting, which would need a much heavier client-side
/// renderer than this app carries.
class _TextExtractPreview extends StatelessWidget {
  const _TextExtractPreview({required this.loading, required this.text});

  final bool loading;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (text == null || text!.trim().isEmpty) {
      return Center(child: Text('No text could be extracted from this document.', style: TextStyle(color: tokens.ink2)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Extracted text — formatting, images and layout aren\'t shown.',
          style: TextStyle(fontSize: 11.5, color: tokens.ink2),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Scrollbar(
            child: SingleChildScrollView(
              child: SelectableText(text!, style: const TextStyle(fontSize: 12.5, height: 1.4)),
            ),
          ),
        ),
      ],
    );
  }
}
