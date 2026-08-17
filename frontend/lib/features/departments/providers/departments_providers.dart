import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/department_row.dart';

final departmentsListProvider = FutureProvider.autoDispose<List<DepartmentRow>>((ref) {
  return ref.watch(departmentsApiProvider).list();
});
