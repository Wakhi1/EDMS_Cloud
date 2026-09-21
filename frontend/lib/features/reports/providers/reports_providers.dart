import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/capacity_stats.dart';
import '../../../core/models/capture_source_stat.dart';
import '../../../core/models/claim_turnaround_point.dart';
import '../../../core/models/count_item.dart';
import '../../../core/models/report_template_row.dart';
import '../../../core/models/retention_status_stat.dart';

/// Every KPI/graph section the Reports screen can show, in display order —
/// mirrors backend/services/reports.service.js's REPORT_SECTIONS exactly
/// (same keys), so the on-screen "Customize" picker, saved report
/// templates, and GET /export's ?sections= filter never disagree.
const kReportSectionDefs = <(String key, String title)>[
  ('by-status', 'Records by status'),
  ('by-department', 'Records by department'),
  ('by-category', 'Records by category'),
  ('by-folder', 'Records by folder (top 15)'),
  ('by-classification', 'Records by classification'),
  ('capacity', 'Storage capacity'),
  ('captured-over-time', 'Records captured over time'),
  ('capture-by-source', 'Capture success by source'),
  ('claim-turnaround', 'Claim turnaround (avg days)'),
  ('retention-status', 'Retention & disposal status'),
  ('overdue-retention', 'Overdue for disposal'),
  ('audit-actions', 'Audit actions breakdown'),
  ('top-users', 'Top audit actors'),
];
final kAllReportSectionKeys = <String>{for (final def in kReportSectionDefs) def.$1};

/// Which sections are currently shown on screen / included in an export —
/// defaults to everything, matching the screen's original always-show-all
/// behavior. Not autoDispose: should survive a Customize dialog close/reopen
/// and a quick tab-away-and-back without resetting to "all" each time.
final selectedReportSectionsProvider = StateProvider<Set<String>>((ref) => kAllReportSectionKeys);

final reportTemplateListProvider = FutureProvider.autoDispose<List<ReportTemplateRow>>((ref) {
  return ref.watch(reportTemplatesApiProvider).list();
});

/// Drives the export dialog's "Include my signature" checkbox — disabled
/// when the signed-in user hasn't saved one (Settings -> My Signature).
final hasSavedSignatureProvider = FutureProvider.autoDispose<bool>((ref) async {
  final meta = await ref.watch(signatureApiProvider).getMeta();
  return meta.hasSignature;
});

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

final reportsOverdueRetentionProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(reportsApiProvider).overdueRetention();
});

final reportsAuditActionsProvider = FutureProvider.autoDispose<List<CountItem>>((ref) {
  final f = ref.watch(reportsFiltersProvider);
  return ref.watch(reportsApiProvider).auditActions(from: f.from, to: f.to);
});

final reportsTopUsersProvider = FutureProvider.autoDispose<List<CountItem>>((ref) {
  final f = ref.watch(reportsFiltersProvider);
  return ref.watch(reportsApiProvider).topUsers(from: f.from, to: f.to);
});
