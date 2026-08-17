import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/system_setting_row.dart';

final systemSettingsListProvider = FutureProvider.autoDispose<List<SystemSettingRow>>((ref) {
  return ref.watch(settingsApiProvider).list();
});
