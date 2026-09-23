import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/approval_item.dart';
import '../../../core/models/count_item.dart';
import '../../../core/models/dashboard_summary.dart';
import '../../../core/models/notification_item.dart';

// Each dashboard section is its own provider (not one combined call) so a
// 403 on one module (e.g. 'reports' for a role that only has 'approvals')
// doesn't blank out sections the role DOES have access to.

/// Role-shaped headline figures (documents / folders / storage by location).
final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((ref) {
  return ref.watch(reportsApiProvider).dashboardSummary();
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
