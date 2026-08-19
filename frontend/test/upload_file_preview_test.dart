import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pspf_edms_app/core/theme/pspf_tokens.dart';
import 'package:pspf_edms_app/features/smart_upload/presentation/widgets/upload_file_preview.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: [PspfTokens.light]),
    home: Scaffold(body: Center(child: child)),
  );
}

// 1x1 red PNG.
final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

const _csvBytes = <int>[
  // Name,Amount\nAlice,10\n"Bob, Jr.",20\n
  78, 97, 109, 101, 44, 65, 109, 111, 117, 110, 116, 10, //
  65, 108, 105, 99, 101, 44, 49, 48, 10, //
  34, 66, 111, 98, 44, 32, 74, 114, 46, 34, 44, 50, 48, 10, //
];

void main() {
  testWidgets('image preview thumb renders and opens a dialog with the image', (tester) async {
    await tester.pumpWidget(
      _wrap(
        UploadFilePreviewThumb(
          bytes: _pngBytes,
          fileName: 'photo.png',
          mimeType: 'image/png',
          extractedText: null,
          extractedTextLoading: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget); // thumbnail

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2)); // thumbnail + full preview
    stdout.writeln('[preview-test] image: OK');
  });

  testWidgets('csv preview thumb opens a dialog rendering a parsed table', (tester) async {
    await tester.pumpWidget(
      _wrap(
        UploadFilePreviewThumb(
          bytes: _csvBytes,
          fileName: 'members.csv',
          mimeType: 'text/csv',
          extractedText: null,
          extractedTextLoading: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.table_chart_outlined), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
    // Header + one data row's known cell values should be present.
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob, Jr.'), findsOneWidget); // proves quoted-comma parsing worked
    stdout.writeln('[preview-test] csv: OK — quoted comma field parsed correctly');
  });

  testWidgets('docx preview thumb shows extracted text once recognition completes', (tester) async {
    await tester.pumpWidget(
      _wrap(
        UploadFilePreviewThumb(
          bytes: const [1, 2, 3], // real bytes irrelevant — docx preview uses extractedText
          fileName: 'policy.docx',
          mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          extractedText: 'Smart Upload preview test document.\nMember number: MEM-2026-0042',
          extractedTextLoading: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.textContaining('MEM-2026-0042'), findsOneWidget);
    stdout.writeln('[preview-test] docx: OK — extracted text shown');
  });

  testWidgets('docx preview thumb shows a spinner while recognition is still running', (tester) async {
    await tester.pumpWidget(
      _wrap(
        UploadFilePreviewThumb(
          bytes: const [1, 2, 3],
          fileName: 'policy.docx',
          mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          extractedText: null,
          extractedTextLoading: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(InkWell));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    stdout.writeln('[preview-test] docx loading state: OK');
  });

  testWidgets('unsupported file type shows a non-clickable generic icon, no dialog', (tester) async {
    await tester.pumpWidget(
      _wrap(
        UploadFilePreviewThumb(
          bytes: const [1, 2, 3],
          fileName: 'archive.zip',
          mimeType: 'application/zip',
          extractedText: null,
          extractedTextLoading: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    stdout.writeln('[preview-test] unsupported type: OK — no dialog opened');
  });
}
