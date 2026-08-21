import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/approval_item.dart';
import '../../../core/models/capacity_stats.dart';
import '../../../core/models/count_item.dart';
import '../../../core/models/notification_item.dart';
import '../../../core/models/retention_status_stat.dart';

// Each dashboard section is its own provider (not one combined call) so a
// 403 on one module (e.g. 'reports' for a role that only has 'approvals')
// doesn't blank out sections the role DOES have access to.

final dashboardByStatusProvider = FutureProvider.autoDispose<List<CountItem>>((ref) {
  return ref.watch(reportsApiProvider).byStatus(silent403: true);
});

final dashboardByDepartmentProvider = FutureProvider.autoDispose<List<CountItem>>((ref) {
  return ref.watch(reportsApiProvider).byDepartment(silent403: true);
});

final dashboardByCategoryProvider = FutureProvider.autoDispose<List<CountItem>>((ref) {
  return ref.watch(reportsApiProvider).byCategory(silent403: true);
});

final dashboardByFolderProvider = FutureProvider.autoDispose<List<CountItem>>((ref) {
  return ref.watch(reportsApiProvider).byFolder(silent403: true);
});

final dashboardCapacityProvider = FutureProvider.autoDispose<CapacityStats>((ref) {
  return ref.watch(reportsApiProvider).capacity(silent403: true);
});

final dashboardApprovalsProvider = FutureProvider.autoDispose<List<ApprovalItem>>((ref) {
  return ref.watch(approvalsApiProvider).inbox(silent403: true);
});

final dashboardNotificationsProvider = FutureProvider.autoDispose<List<NotificationItem>>((ref) {
  return ref.watch(notificationsApiProvider).list();
});

final dashboardOverdueRetentionProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(reportsApiProvider).overdueRetention(silent403: true);
});

final dashboardCapturedOverTimeProvider = FutureProvider.autoDispose<List<CountItem>>((ref) {
  return ref.watch(reportsApiProvider).capturedOverTime(silent403: true);
});

final dashboardRetentionStatusProvider = FutureProvider.autoDispose<List<RetentionStatusStat>>((ref) {
  return ref.watch(reportsApiProvider).retentionStatus(silent403: true);
});
