import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/notification_item.dart';

final notificationsListProvider = FutureProvider.autoDispose<List<NotificationItem>>((ref) {
  return ref.watch(notificationsApiProvider).list();
});
