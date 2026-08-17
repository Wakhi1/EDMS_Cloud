import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/models/document_type_row.dart';
import '../../../core/models/folder_row.dart';
import '../../../core/models/ocr_preview_result.dart';
import 'upload_batch_storage_provider.dart';

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
      recordNo: recordNo != null ? recordNo() : this.recordNo,
      customFields: customFields ?? this.customFields,
      duplicateOf: duplicateOf != null ? duplicateOf() : this.duplicateOf,
      allowDuplicate: allowDuplicate ?? this.allowDuplicate,
    );
  }
}

class UploadQueueNotifier extends Notifier<List<UploadRow>> {
  static final _random = Random();

  @override
  List<UploadRow> build() => const [];

  void addFiles(List<({List<int> bytes, String fileName, String mimeType})> files) {
    final newRows = [
      for (final f in files)
        UploadRow(
          localId: '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(100000)}',
          bytes: f.bytes,
          fileName: f.fileName,
          mimeType: f.mimeType,
          title: _titleFromFileName(f.fileName),
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
          documentTypeId: () => result.suggestedDocumentTypeId,
          memberNumber: result.suggestedMemberNumber ?? r.memberNumber,
          duplicateOf: () => result.duplicateOf,
        ),
      );
    } on ApiException catch (e) {
      _updateRow(
        localId,
        (r) => r.copyWith(status: UploadRowStatus.recognitionFailed, error: () => e.message),
      );
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
      ),
    );
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

  /// Commits every row that's ready (recognized, has a type+folder chosen)
  /// via the real registration endpoint, generating a client-side record
  /// number and retrying once on a 409 (duplicate) response. [folders] is
  /// used to derive each row's storage prefix from its chosen repository
  /// folder, unless the batch storage location has an explicit override.
  Future<void> commitAll(List<DocumentTypeRow> types, List<FolderRow> folders) async {
    for (final row in state) {
      if (row.status == UploadRowStatus.committed) continue;
      if (row.documentTypeId == null || row.folderId == null) continue;
      if (row.duplicateOf != null && !row.allowDuplicate) continue; // needs an explicit "upload anyway"
      await _commitRow(row.localId, types, folders);
    }
  }

  Future<void> _commitRow(String localId, List<DocumentTypeRow> types, List<FolderRow> folders) async {
    _updateRow(localId, (r) => r.copyWith(status: UploadRowStatus.committing));
    final row = state.firstWhere((r) => r.localId == localId);
    final typeCode = types.firstWhere((t) => t.id == row.documentTypeId, orElse: () => types.first).code;

    final batchStorage = ref.read(uploadBatchStorageProvider);
    final folder = folders.where((f) => f.id == row.folderId).firstOrNull;
    final storagePrefix = batchStorage.prefixOverride ?? (folder != null ? sanitizeStoragePrefix(folder.path) : null);

    var attempt = 0;
    while (attempt < 3) {
      attempt += 1;
      final recordNo = _generateRecordNo(typeCode);
      try {
        await ref.read(documentsApiProvider).create(
              recordNo: recordNo,
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
        _updateRow(localId, (r) => r.copyWith(status: UploadRowStatus.committed, recordNo: () => recordNo));
        return;
      } on ApiException catch (e) {
        if (e.statusCode == 409 && attempt < 3) continue; // regenerate and retry
        _updateRow(localId, (r) => r.copyWith(status: UploadRowStatus.commitFailed, error: () => e.message));
        return;
      }
    }
  }

  static String _generateRecordNo(String typeCode) {
    final year = DateTime.now().year;
    final suffix = (DateTime.now().microsecondsSinceEpoch + _random.nextInt(9999)) % 10000;
    return '$typeCode-$year-${suffix.toString().padLeft(4, '0')}';
  }
}

final uploadQueueProvider = NotifierProvider<UploadQueueNotifier, List<UploadRow>>(UploadQueueNotifier.new);
