import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/watermark_template_row.dart';

final watermarkTemplateListProvider = FutureProvider.autoDispose<List<WatermarkTemplateRow>>((ref) {
  return ref.watch(watermarkTemplatesApiProvider).list();
});

final activeWatermarkTemplateProvider = FutureProvider.autoDispose<WatermarkTemplateRow?>((ref) {
  return ref.watch(watermarkTemplatesApiProvider).active();
});
