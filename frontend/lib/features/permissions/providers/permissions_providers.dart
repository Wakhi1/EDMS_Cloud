import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/access_request_row.dart';
import '../../../core/models/acl_entry_row.dart';
import '../../../core/models/permission_matrix_cell.dart';

/// silent403: someone without 'permissions' module access must still be
/// able to land on the target screen to use the "Request access" flow —
/// see permissions_target_screen.dart's handling of a forbidden [aclAsync].
final aclProvider = FutureProvider.autoDispose.family<({List<AclEntryRow> own, List<AclEntryRow> inherited}), (String, String)>(
  (ref, target) => ref.watch(permissionsApiProvider).getAcl(target.$1, target.$2, silent403: true),
);

/// silent403: the bare /permissions screen also serves non-admin users via
/// its target-picker hint section — a 403 on the matrix alone must not
/// bounce the whole screen to /access-denied.
final permissionMatrixProvider = FutureProvider.autoDispose<List<PermissionMatrixCell>>((ref) {
  return ref.watch(permissionsApiProvider).matrix(silent403: true);
});

/// silent403: same reasoning as [permissionMatrixProvider] — a non-approver
/// (no 'permissions' edit access) reaching the bare /permissions screen
/// must not get bounced to /access-denied just because the queue section
/// alone is gated.
final accessRequestsQueueProvider = FutureProvider.autoDispose<List<AccessRequestRow>>((ref) {
  return ref.watch(accessRequestsApiProvider).listQueue(status: 'pending', silent403: true);
});
