import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/workflow_row.dart';

final workflowsProvider = FutureProvider.autoDispose<List<WorkflowRow>>((ref) {
  return ref.watch(workflowApiProvider).list();
});

/// Id of the workflow currently loaded into the designer's edit form, or
/// null when the form is in "new workflow" mode.
final editingWorkflowIdProvider = StateProvider.autoDispose<int?>((ref) => null);
