import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/resources/api_keys_api.dart';
import '../../../core/models/integration_row.dart';

final integrationsListProvider = FutureProvider.autoDispose<List<IntegrationRow>>((ref) {
  return ref.watch(integrationsApiProvider).list();
});

final storageLocationProvider = FutureProvider.autoDispose<String>((ref) {
  return ref.watch(integrationsApiProvider).getStorageLocation();
});

/// id+name for just the four storage-type connectors — reachable by any
/// 'capture' role, unlike [integrationsListProvider] (admin-only, includes
/// sensitive config). Used by Smart Upload's storage-location picker.
final storageOptionsProvider = FutureProvider.autoDispose<List<({String id, String name})>>((ref) {
  return ref.watch(integrationsApiProvider).storageOptions();
});

/// Local watched-folder agent credentials — see /local-agent at the repo
/// root and routes/agentUpload.routes.js.
final apiKeysListProvider = FutureProvider.autoDispose<List<ApiKeyRow>>((ref) {
  return ref.watch(apiKeysApiProvider).list();
});
