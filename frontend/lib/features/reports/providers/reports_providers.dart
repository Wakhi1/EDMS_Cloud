import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/capacity_stats.dart';
import '../../../core/models/capture_source_stat.dart';
import '../../../core/models/claim_turnaround_point.dart';
import '../../../core/models/count_item.dart';
import '../../../core/models/retention_status_stat.dart';

// Deliberately separate from dashboard_providers.dart's silent403 versions:
// Reports is a primary screen whose entire purpose is the gated module, so
// a 403 here should redirect to /access-denied like everywhere else, not
// degrade in place like Dashboard's preview widgets.

/// Filters shared across every Reports card — same "one StateProvider, every
/// data provider watches it" shape as audit_providers.dart's AuditFilters.
class ReportsFilters {
  const ReportsFilters({this.from, this.to, this.departmentId, this.documentTypeId, this.folderId, this.classification});

  final String? from; // yyyy-MM-dd
  final String? to; // yyyy-MM-dd
  final int? departmentId;
  final int? documentTypeId;
  final int? folderId;
  final String? classification;

  bool get isEmpty => from == null && to == null && departmentId == null && documentTypeId == null && folderId == null && classification == null;

  ReportsFilters copyWith({
    String? Function()? from,
    String? Function()? to,
    int? Function()? departmentId,
    int? Function()? documentTypeId,
    int? Function()? folderId,
    String? Function()? classification,
  }) {
    return ReportsFilters(
      from: from != null ? from() : this.from,
      to: to != null ? to() : this.to,
      departmentId: departmentId != null ? departmentId() : this.departmentId,
      documentTypeId: documentTypeId != null ? documentTypeId() : this.documentTypeId,
      folderId: folderId != null ? folderId() : this.folderId,
      classification: classification != null ? classification() : this.classification,
    );
  }
}

final reportsFiltersProvider = StateProvider<ReportsFilters>((ref) => const ReportsFilters());

final reportsByStatusProvider = FutureProvider.autoDispose<List<CountItem>>((ref) {
  final f = ref.watch(reportsFiltersProvider);
  return ref.watch(reportsApiProvider).byStatus(
        from: f.from, to: f.to, departmentId: f.departmentId, documentTypeId: f.documentTypeId, folderId: f.folderId, classification: f.classification,
      );
});

final reportsByDepartmentProvider = FutureProvider.autoDispose<List<CountItem>>((ref) {
  final f = ref.watch(reportsFiltersProvider);
  return ref.watch(reportsApiProvider).byDepartment(
        from: f.from, to: f.to, documentTypeId: f.documentTypeId, folderId: f.folderId, classification: f.classification,
      );
});

final reportsByCategoryProvider = FutureProvider.autoDispose<List<CountItem>>((ref) {
  final f = ref.watch(reportsFiltersProvider);
  return ref.watch(reportsApiProvider).byCategory(
        from: f.from, to: f.to, departmentId: f.departmentId, folderId: f.folderId, classification: f.classification,
      );
});

final reportsByFolderProvider = FutureProvider.autoDispose<List<CountItem>>((ref) {
  final f = ref.watch(reportsFiltersProvider);
  return ref.watch(reportsApiProvider).byFolder(
        from: f.from, to: f.to, departmentId: f.departmentId, documentTypeId: f.documentTypeId, classification: f.classification,
      );
});

final reportsByClassificationProvider = FutureProvider.autoDispose<List<CountItem>>((ref) {
  final f = ref.watch(reportsFiltersProvider);
  return ref.watch(reportsApiProvider).byClassification(
        from: f.from, to: f.to, departmentId: f.departmentId, documentTypeId: f.documentTypeId, folderId: f.folderId,
      );
});

final reportsCapacityProvider = FutureProvider.autoDispose<CapacityStats>((ref) {
  return ref.watch(reportsApiProvider).capacity();
});

final reportsCapturedOverTimeProvider = FutureProvider.autoDispose<List<CountItem>>((ref) {
  final f = ref.watch(reportsFiltersProvider);
  return ref.watch(reportsApiProvider).capturedOverTime(
        from: f.from, to: f.to, departmentId: f.departmentId, documentTypeId: f.documentTypeId, folderId: f.folderId, classification: f.classification,
      );
});

final reportsCaptureBySourceProvider = FutureProvider.autoDispose<List<CaptureSourceStat>>((ref) {
  final f = ref.watch(reportsFiltersProvider);
  return ref.watch(reportsApiProvider).captureBySource(from: f.from, to: f.to);
});

final reportsRetentionStatusProvider = FutureProvider.autoDispose<List<RetentionStatusStat>>((ref) {
  final f = ref.watch(reportsFiltersProvider);
  return ref.watch(reportsApiProvider).retentionStatus(
        from: f.from, to: f.to, departmentId: f.departmentId, documentTypeId: f.documentTypeId, folderId: f.folderId, classification: f.classification,
      );
});

final reportsClaimTurnaroundProvider = FutureProvider.autoDispose<List<ClaimTurnaroundPoint>>((ref) {
  final f = ref.watch(reportsFiltersProvider);
  return ref.watch(reportsApiProvider).claimTurnaround(from: f.from, to: f.to);
});

final reportsAuditActionsProvider = FutureProvider.autoDispose<List<CountItem>>((ref) {
  final f = ref.watch(reportsFiltersProvider);
  return ref.watch(reportsApiProvider).auditActions(from: f.from, to: f.to);
});

final reportsTopUsersProvider = FutureProvider.autoDispose<List<CountItem>>((ref) {
  final f = ref.watch(reportsFiltersProvider);
  return ref.watch(reportsApiProvider).topUsers(from: f.from, to: f.to);
});
