import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/document_record.dart';

final documentDetailProvider = FutureProvider.autoDispose.family<DocumentRecord, int>((ref, id) {
  return ref.watch(documentsApiProvider).getById(id);
});

/// Only watched once the "Extracted text" panel is expanded — see
/// document_viewer/presentation/viewer_screen.dart's _ExtractedTextPanel.
final documentOcrTextProvider = FutureProvider.autoDispose.family<String?, int>((ref, id) {
  return ref.watch(documentsApiProvider).ocrText(id);
});
