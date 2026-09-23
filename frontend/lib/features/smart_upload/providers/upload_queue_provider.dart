import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/folder_row.dart';
import '../../../core/models/ocr_preview_result.dart';
import '../../../core/models/record_index_row.dart';
import 'upload_batch_storage_provider.dart';

/// Available record_indexes for one document type, cached per type so
/// switching between two rows of the same type doesn't refetch. Watched
/// directly by the review table's per-row "Record index" dropdown.
final availableRecordIndexesProvider = FutureProvider.autoDispose.family<List<RecordIndexRow>, int>((ref, documentTypeId) {
  return ref.watch(recordIndexesApiProvider).available(documentTypeId);
});

/// Derives a cloud-safe storage prefix from a repository folder's display
/// path (e.g. "Pension Claims / 2026" -> "pension-claims/2026"), so picking/
/// creating a repository folder also determines where the bytes physically
/// land by default, with no separate decision required for the common case.
String sanitizeStoragePrefix(String folderPath) {
  return folderPath
      .split('/')
      .map((segment) => segment.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), ''))
      .where((segment) => segment.isNotEmpty)
      .join('/');
}

enum UploadRowStatus { queued, recognizing, recognized, recognitionFailed, committing, committed, commitFailed }

/// One file in the Smart Upload review queue. Plain immutable class (no
/// freezed/codegen) — this is transient UI state, not an API DTO.
class UploadRow {
  const UploadRow({
    required this.localId,
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    this.status = UploadRowStatus.queued,
    this.error,
    this.extractedText,
    this.confidence,
    this.title = '',
    this.documentTypeId,
    this.folderId,
    this.memberNumber = '',
    this.classification = 'internal',
    this.recordIndexId,
    this.recordNo,
    this.customFields = const [],
    this.duplicateOf,
    this.allowDuplicate = false,
  });

  final String localId;
  final List<int> bytes;
  final String fileName;
  final String mimeType;
  final UploadRowStatus status;
  final String? error;
  final String? extractedText;
  final int? confidence;
  final String title;
  final int? documentTypeId;
  final int? folderId;
  final String memberNumber;
  final String classification;

  /// The admin-issued index the user picked from GET /available for this
  /// row's [documentTypeId] — required to commit. Cleared whenever
  /// [documentTypeId] changes, since an index belongs to exactly one type.
  final int? recordIndexId;

  /// Set only after a successful commit, from the server's response —
  /// distinct from [recordIndexId], which is the pre-commit selection.
  final String? recordNo;

  /// Set from ocr-preview's content-hash duplicate check, before commit.
  final DuplicateOfInfo? duplicateOf;

  /// User has acknowledged [duplicateOf] and wants to upload anyway.
  final bool allowDuplicate;

  /// Optional user-defined label:value tags — "custom indexing" beyond the
  /// fixed document_type/folder/member fields, searchable via
  /// document_custom_fields.
  final List<({String label, String value})> customFields;

  bool get needsAttention => status == UploadRowStatus.recognitionFailed || status == UploadRowStatus.commitFailed;

  /// What still has to be filled in before this file can be registered.
  List<String> get missing => [
    if (documentTypeId == null) 'type',
    if (documentTypeId != null && recordIndexId == null) 'record no.',
    if (folderId == null) 'folder',
    if (duplicateOf != null && !allowDuplicate) 'duplicate confirmation',
  ];

  bool get isBusy => status == UploadRowStatus.recognizing || status == UploadRowStatus.committing;

  /// Recognised (or failed only at commit) and nothing missing.
  bool get isReady => !isBusy && status != UploadRowStatus.committed && status != UploadRowStatus.queued && missing.isEmpty;

  UploadRow copyWith({
    UploadRowStatus? status,
    String? Function()? error,
    String? Function()? extractedText,
    int? Function()? confidence,
    String? title,
    int? Function()? documentTypeId,
    int? Function()? folderId,
    String? memberNumber,
    String? classification,
    int? Function()? recordIndexId,
    String? Function()? recordNo,
    List<({String label, String value})>? customFields,
    DuplicateOfInfo? Function()? duplicateOf,
    bool? allowDuplicate,
  }) {
    return UploadRow(
      localId: localId,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      status: status ?? this.status,
      error: error != null ? error() : this.error,
      extractedText: extractedText != null ? extractedText() : this.extractedText,
      confidence: confidence != null ? confidence() : this.confidence,
      title: title ?? this.title,
      documentTypeId: documentTypeId != null ? documentTypeId() : this.documentTypeId,
      folderId: folderId != null ? folderId() : this.folderId,
      memberNumber: memberNumber ?? this.memberNumber,
      classification: classification ?? this.classification,
      recordIndexId: recordIndexId != null ? recordIndexId() : this.recordIndexId,
      recordNo: recordNo != null ? recordNo() : this.recordNo,
      customFields: customFields ?? this.customFields,
      duplicateOf: duplicateOf != null ? duplicateOf() : this.duplicateOf,
      allowDuplicate: allowDuplicate ?? this.allowDuplicate,
    );
  }
}

/// Values applied to every file added to the queue (and, on request, to the
/// files already in it) so a batch is configured once, not file by file.
class UploadDefaults {
  const UploadDefaults({this.folderId, this.documentTypeId, this.classification = 'internal'});

  final int? folderId;

  /// null = keep each file's auto-detected type.
  final int? documentTypeId;
  final String classification;
}

final uploadDefaultsProvider = StateProvider<UploadDefaults>((ref) => const UploadDefaults());

class UploadQueueNotifier extends Notifier<List<UploadRow>> {
  static final _random = Random();

  @override
  List<UploadRow> build() => const [];

  void addFiles(List<({List<int> bytes, String fileName, String mimeType})> files) {
    final defaults = ref.read(uploadDefaultsProvider);
    final newRows = [
      for (final f in files)
        UploadRow(
          localId: '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(100000)}',
          bytes: f.bytes,
          fileName: f.fileName,
          mimeType: f.mimeType,
          title: _titleFromFileName(f.fileName),
          folderId: defaults.folderId,
          documentTypeId: defaults.documentTypeId,
          classification: defaults.classification,
        ),
    ];
    state = [...state, ...newRows];
    for (final row in newRows) {
      _runOcrPreview(row.localId);
    }
  }

  static String _titleFromFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final base = dot > 0 ? fileName.substring(0, dot) : fileName;
    return base.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  }

  Future<void> _runOcrPreview(String localId) async {
    _updateRow(localId, (r) => r.copyWith(status: UploadRowStatus.recognizing));
    try {
      final row = state.firstWhere((r) => r.localId == localId);
      final result = await ref.read(documentsApiProvider).ocrPreview(
            fileBytes: row.bytes,
            fileName: row.fileName,
            mimeType: row.mimeType,
          );
      _updateRow(
        localId,
        (r) => r.copyWith(
          status: UploadRowStatus.recognized,
          extractedText: () => result.text,
          confidence: () => result.confidence,
          // A type the user already picked while recognition ran wins over the suggestion.
          documentTypeId: () => r.documentTypeId ?? result.suggestedDocumentTypeId,
          memberNumber: result.suggestedMemberNumber ?? r.memberNumber,
          duplicateOf: () => result.duplicateOf,
        ),
      );
      await _autoPickIndex(localId);
    } on ApiException catch (e) {
      _updateRow(
        localId,
        (r) => r.copyWith(status: UploadRowStatus.recognitionFailed, error: () => e.message),
      );
    }
  }

  /// Gives a row the next available record number for its type, skipping
  /// numbers other rows in this batch already hold. The user can change it.
  Future<void> _autoPickIndex(String localId) async {
    final row = state.where((r) => r.localId == localId).firstOrNull;
    if (row == null || row.documentTypeId == null || row.recordIndexId != null) return;
    final typeId = row.documentTypeId!;
    List<RecordIndexRow> available;
    try {
      available = await ref.read(availableRecordIndexesProvider(typeId).future);
    } on ApiException {
      return;
    }
    // Re-read after the await: the row may have changed type, or another row
    // may have taken a number meanwhile.
    final current = state.where((r) => r.localId == localId).firstOrNull;
    if (current == null || current.documentTypeId != typeId || current.recordIndexId != null) return;
    final taken = {for (final r in state) if (r.recordIndexId != null) r.recordIndexId!};
    final next = available.where((i) => !taken.contains(i.id)).firstOrNull;
    if (next != null) _updateRow(localId, (r) => r.copyWith(recordIndexId: () => next.id));
  }

  /// Applies the batch defaults to files already queued. With [overwrite]
  /// false only empty fields are filled.
  void applyDefaults({bool overwrite = false}) {
    final d = ref.read(uploadDefaultsProvider);
    final retyped = <String>[];
    UploadRow apply(UploadRow r) {
      if (r.status == UploadRowStatus.committed) return r;
      final setType = d.documentTypeId != null && (overwrite || r.documentTypeId == null) && r.documentTypeId != d.documentTypeId;
      if (setType) retyped.add(r.localId);
      return r.copyWith(
        folderId: d.folderId != null && (overwrite || r.folderId == null) ? () => d.folderId : null,
        documentTypeId: setType ? () => d.documentTypeId : null,
        recordIndexId: setType ? () => null : null,
        classification: overwrite ? d.classification : null,
      );
    }

    state = [for (final r in state) apply(r)];
    for (final id in retyped) {
      _autoPickIndex(id);
    }
  }

  void updateField(
    String localId, {
    String? title,
    int? Function()? documentTypeId,
    int? Function()? folderId,
    String? memberNumber,
    String? classification,
  }) {
    _updateRow(
      localId,
      (r) => r.copyWith(
        title: title,
        documentTypeId: documentTypeId,
        folderId: folderId,
        memberNumber: memberNumber,
        classification: classification,
        // An index belongs to exactly one type — changing the type
        // invalidates whatever was picked before.
        recordIndexId: documentTypeId != null ? () => null : null,
      ),
    );
    if (documentTypeId != null) _autoPickIndex(localId);
  }

  /// Sets the row's chosen record index (from GET /available). The screen
  /// is responsible for only offering ids not already picked by another
  /// row in this same queue.
  void setRecordIndex(String localId, int? recordIndexId) {
    _updateRow(localId, (r) => r.copyWith(recordIndexId: () => recordIndexId));
  }

  void addCustomField(String localId, String label, String value) {
    if (label.trim().isEmpty || value.trim().isEmpty) return;
    _updateRow(
      localId,
      (r) => r.copyWith(customFields: [...r.customFields, (label: label.trim(), value: value.trim())]),
    );
  }

  void setAllowDuplicate(String localId, bool value) {
    _updateRow(localId, (r) => r.copyWith(allowDuplicate: value));
  }

  void removeCustomField(String localId, int index) {
    _updateRow(
      localId,
      (r) => r.copyWith(customFields: [for (var i = 0; i < r.customFields.length; i++) if (i != index) r.customFields[i]]),
    );
  }

  void removeRow(String localId) {
    state = state.where((r) => r.localId != localId).toList(growable: false);
  }

  void _updateRow(String localId, UploadRow Function(UploadRow) update) {
    state = [
      for (final r in state) r.localId == localId ? update(r) : r,
    ];
  }

  /// Commits every row that's ready (recognized, has a type+folder+record
  /// index chosen) via the real registration endpoint. [folders] is used to
  /// derive each row's storage prefix from its chosen repository folder,
  /// unless the batch storage location has an explicit override.
  Future<void> commitAll(List<FolderRow> folders) async {
    for (final row in [...state]) {
      if (!row.isReady) continue; // the screen lists what each skipped file is missing
      await _commitRow(row.localId, folders);
    }
  }

  void clearRegistered() {
    state = state.where((r) => r.status != UploadRowStatus.committed).toList(growable: false);
  }

  Future<void> _commitRow(String localId, List<FolderRow> folders) async {
    _updateRow(localId, (r) => r.copyWith(status: UploadRowStatus.committing));
    final row = state.firstWhere((r) => r.localId == localId);

    final batchStorage = ref.read(uploadBatchStorageProvider);
    final folder = folders.where((f) => f.id == row.folderId).firstOrNull;
    final storagePrefix = batchStorage.prefixOverride ?? (folder != null ? sanitizeStoragePrefix(folder.path) : null);

    try {
      final result = await ref.read(documentsApiProvider).create(
            recordIndexId: row.recordIndexId!,
            title: row.title.isEmpty ? row.fileName : row.title,
            documentTypeId: row.documentTypeId!,
            folderId: row.folderId!,
            memberNumber: row.memberNumber.isEmpty ? null : row.memberNumber,
            classification: row.classification,
            storageProviderId: batchStorage.providerId,
            storagePrefix: storagePrefix,
            customFields: row.customFields,
            allowDuplicate: row.allowDuplicate,
            fileBytes: row.bytes,
            fileName: row.fileName,
            mimeType: row.mimeType,
          );
      _updateRow(localId, (r) => r.copyWith(status: UploadRowStatus.committed, recordNo: () => result.recordNo));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // Someone else claimed it between selection and commit — the
        // picked id no longer exists in the available pool, so clear it
        // and refresh that list rather than blindly retrying a guess.
        ref.invalidate(availableRecordIndexesProvider(row.documentTypeId!));
        _updateRow(
          localId,
          (r) => r.copyWith(
            status: UploadRowStatus.commitFailed,
            recordIndexId: () => null,
            error: () => 'That record index was just taken — pick another.',
          ),
        );
        return;
      }
      _updateRow(localId, (r) => r.copyWith(status: UploadRowStatus.commitFailed, error: () => e.message));
    }
  }
}

final uploadQueueProvider = NotifierProvider<UploadQueueNotifier, List<UploadRow>>(UploadQueueNotifier.new);
