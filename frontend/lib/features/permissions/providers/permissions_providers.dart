import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/acl_entry_row.dart';
import '../../../core/models/permission_matrix_cell.dart';

final aclProvider = FutureProvider.autoDispose.family<({List<AclEntryRow> own, List<AclEntryRow> inherited}), (String, String)>(
  (ref, target) => ref.watch(permissionsApiProvider).getAcl(target.$1, target.$2),
);

/// silent403: the bare /permissions screen also serves non-admin users via
/// its target-picker hint section — a 403 on the matrix alone must not
/// bounce the whole screen to /access-denied.
final permissionMatrixProvider = FutureProvider.autoDispose<List<PermissionMatrixCell>>((ref) {
  return ref.watch(permissionsApiProvider).matrix(silent403: true);
});
