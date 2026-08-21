import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/share_link.dart';

final shareLinksProvider = FutureProvider.autoDispose<List<ShareLink>>((ref) {
  return ref.watch(sharingApiProvider).list();
});
