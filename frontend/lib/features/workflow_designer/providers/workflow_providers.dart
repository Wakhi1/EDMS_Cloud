import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/workflow_row.dart';

final workflowsProvider = FutureProvider.autoDispose<List<WorkflowRow>>((ref) {
  return ref.watch(workflowApiProvider).list();
});
