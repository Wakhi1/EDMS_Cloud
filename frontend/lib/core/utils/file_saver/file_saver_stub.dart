import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Desktop/mobile: shows the native "Save As" dialog, then writes the file.
/// Returns false if the user cancels.
Future<bool> saveBytes({required List<int> bytes, required String fileName, String? mimeType}) async {
  final data = Uint8List.fromList(bytes);
  final dot = fileName.lastIndexOf('.');
  final extension = dot > 0 ? fileName.substring(dot + 1) : null;
  final uri = await FilePicker.saveFile(
    fileName: fileName,
    bytes: data,
    mimeType: mimeType ?? 'application/octet-stream',
    dialogTitle: 'Save $fileName',
    type: extension == null ? FileType.any : FileType.custom,
    allowedExtensions: extension == null ? null : [extension],
  );
  if (uri == null) return false;
  if (uri.scheme != 'file') return true;

  // Some platforms only return the chosen path; make sure the bytes are there.
  final file = File.fromUri(uri);
  if (!file.existsSync() || file.lengthSync() != data.length) {
    await file.writeAsBytes(data, flush: true);
  }
  return true;
}
