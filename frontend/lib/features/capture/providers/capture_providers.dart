import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/capture_batch_row.dart';
import '../../../core/models/capture_batch_summary.dart';

final captureBatchesSummaryProvider = FutureProvider.autoDispose<List<CaptureBatchSummary>>((ref) {
  return ref.watch(captureBatchesApiProvider).summary();
});

class CaptureBatchFilters {
  const CaptureBatchFilters({this.source, this.status});

  final String? source;
  final String? status;

  CaptureBatchFilters copyWith({String? Function()? source, String? Function()? status}) {
    return CaptureBatchFilters(
      source: source != null ? source() : this.source,
      status: status != null ? status() : this.status,
    );
  }
}

final captureBatchFiltersProvider = StateProvider.autoDispose<CaptureBatchFilters>((ref) => const CaptureBatchFilters());

final captureBatchListProvider = FutureProvider.autoDispose<List<CaptureBatchRow>>((ref) {
  final filters = ref.watch(captureBatchFiltersProvider);
  return ref.watch(captureBatchesApiProvider).list(source: filters.source, status: filters.status);
});

final captureBatchDetailProvider = FutureProvider.autoDispose.family<CaptureBatchDetail, int>((ref, id) {
  return ref.watch(captureBatchesApiProvider).detail(id);
});

final captureConnectorStatusProvider = FutureProvider.autoDispose<List<CaptureConnectorStatus>>((ref) {
  return ref.watch(captureBatchesApiProvider).connectorStatus();
});
