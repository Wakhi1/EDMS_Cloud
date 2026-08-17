import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Batch-level (not per-file) storage-location choice for the current Smart
/// Upload session — one location applies to every file added, per product
/// decision. `providerId: null` means "use whatever the global active
/// storage provider is" (today's behaviour, unchanged); `prefixOverride:
/// null` means "derive the storage folder from whichever repository folder
/// each file is destined for" rather than a manually browsed/created one.
class UploadBatchStorage {
  const UploadBatchStorage({this.providerId, this.prefixOverride});

  final String? providerId;
  final String? prefixOverride;
}

class UploadBatchStorageNotifier extends Notifier<UploadBatchStorage> {
  @override
  UploadBatchStorage build() => const UploadBatchStorage();

  void setLocation({String? providerId, String? prefixOverride}) {
    state = UploadBatchStorage(providerId: providerId, prefixOverride: prefixOverride);
  }

  void reset() => state = const UploadBatchStorage();
}

final uploadBatchStorageProvider = NotifierProvider<UploadBatchStorageNotifier, UploadBatchStorage>(
  UploadBatchStorageNotifier.new,
);
