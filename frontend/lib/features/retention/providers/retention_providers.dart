import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/retention_class_row.dart';
import '../../../core/models/retention_due_item.dart';

final retentionClassesProvider = FutureProvider.autoDispose<List<RetentionClassRow>>((ref) {
  return ref.watch(retentionApiProvider).classes();
});

final retentionDueProvider = FutureProvider.autoDispose<List<RetentionDueItem>>((ref) {
  return ref.watch(retentionApiProvider).due();
});
