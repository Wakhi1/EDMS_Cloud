import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

import '../../theme/pspf_tokens.dart';

/// CSV preview — parsed with proper RFC4180 quoting/escaping (not a naive
/// String.split(',')) and rendered as a scrollable table. No external
/// package handles CSV *rendering*; only parsing needs one.
class CsvPreview extends StatelessWidget {
  const CsvPreview({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    List<List<dynamic>> rows;
    try {
      rows = csv.decode(utf8.decode(bytes));
    } catch (e) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Couldn\'t parse this CSV file: $e', style: TextStyle(color: tokens.bad), textAlign: TextAlign.center),
        ),
      );
    }
    if (rows.isEmpty) {
      return Center(child: Text('This CSV file is empty.', style: TextStyle(color: tokens.ink2)));
    }

    final header = rows.first;
    final body = rows.skip(1).toList();

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(tokens.surf2),
            columns: [for (final cell in header) DataColumn(label: Text('$cell', style: const TextStyle(fontWeight: FontWeight.w600)))],
            rows: [
              for (final row in body)
                DataRow(cells: [for (var i = 0; i < header.length; i++) DataCell(Text(i < row.length ? '${row[i]}' : ''))]),
            ],
          ),
        ),
      ),
    );
  }
}
