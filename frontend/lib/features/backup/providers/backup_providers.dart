import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/backup_row.dart';

final backupsListProvider = FutureProvider.autoDispose<List<BackupRow>>((ref) {
  return ref.watch(backupApiProvider).list();
});
