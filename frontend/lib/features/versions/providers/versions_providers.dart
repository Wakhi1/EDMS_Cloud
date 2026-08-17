import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/document_version_row.dart';

final documentVersionsProvider = FutureProvider.autoDispose.family<List<DocumentVersionRow>, int>((ref, documentId) {
  return ref.watch(versionsApiProvider).list(documentId);
});
