import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/approval_item.dart';

/// The real Approvals screen's inbox — unlike the Dashboard's preview
/// (features/dashboard/providers/dashboard_providers.dart, which passes
/// silent403 so a 403 there degrades in place), a 403 on this screen
/// SHOULD trigger the global redirect to /access-denied, since this is
/// the primary destination, not an auxiliary widget.
final approvalsInboxProvider = FutureProvider.autoDispose<List<ApprovalItem>>((ref) {
  return ref.watch(approvalsApiProvider).inbox();
});
