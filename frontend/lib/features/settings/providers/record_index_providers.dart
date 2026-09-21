import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/record_index_row.dart';

class RecordIndexFilters {
  const RecordIndexFilters({this.documentTypeId, this.status});

  final int? documentTypeId;
  final String? status;

  RecordIndexFilters copyWith({int? Function()? documentTypeId, String? Function()? status}) {
    return RecordIndexFilters(
      documentTypeId: documentTypeId != null ? documentTypeId() : this.documentTypeId,
      status: status != null ? status() : this.status,
    );
  }
}

final recordIndexFiltersProvider = StateProvider.autoDispose<RecordIndexFilters>((ref) => const RecordIndexFilters());

final recordIndexListProvider = FutureProvider.autoDispose<List<RecordIndexRow>>((ref) {
  final filters = ref.watch(recordIndexFiltersProvider);
  return ref.watch(recordIndexesApiProvider).list(documentTypeId: filters.documentTypeId, status: filters.status);
});
