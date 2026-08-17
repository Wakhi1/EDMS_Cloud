import 'dart:convert';

import 'package:dio/dio.dart';

import '../../models/document_record.dart';
import '../../models/ocr_preview_result.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/documents.routes.js.
class DocumentsApi {
  DocumentsApi(this._client);

  final ApiClient _client;

  /// GET /api/documents — flat list, max 200 rows, no pagination. Filtering
  /// is via named query params, all optional.
  Future<List<DocumentRecord>> search({
    String? q,
    int? folderId,
    int? departmentId,
    String? status,
    int? documentTypeId,
    int? captureBatchId,
  }) async {
    final response = await _client.get(
      Endpoints.documents,
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        'folderId': ?folderId,
        'departmentId': ?departmentId,
        if (status != null && status.isNotEmpty) 'status': status,
        'documentTypeId': ?documentTypeId,
        'captureBatchId': ?captureBatchId,
      },
    );
    return _client.unwrapList(response, DocumentRecord.fromJson);
  }

  Future<DocumentRecord> getById(int id) async {
    final response = await _client.get(Endpoints.documentById('$id'));
    return _client.unwrap(response, (data) => DocumentRecord.fromJson(data as Map<String, dynamic>));
  }

  /// GET /api/documents/:id/ocr-text — separate from [getById] since
  /// ocr_text is MEDIUMTEXT; fetched lazily only when the viewer's
  /// "Extracted text" panel is opened.
  Future<String?> ocrText(int id) async {
    final response = await _client.get(Endpoints.documentOcrText('$id'));
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['text'] as String?);
  }

  /// GET /api/documents/:id/content — the whole decrypted file, buffered in
  /// one response (no range/streaming support server-side). [reason] is
  /// required by the backend when the document's classification is
  /// 'confidential' (else 400).
  Future<({List<int> bytes, String? contentType, String? fileName})> content(int id, {String? reason}) async {
    final response = await _client.get(
      Endpoints.documentContent('$id'),
      queryParameters: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      options: Options(responseType: ResponseType.bytes),
    );
    final contentType = response.headers.value('content-type');
    final disposition = response.headers.value('content-disposition');
    final fileName = _fileNameFrom(disposition);
    return (bytes: (response.data as List<int>?) ?? const [], contentType: contentType, fileName: fileName);
  }

  static String? _fileNameFrom(String? contentDisposition) {
    if (contentDisposition == null) return null;
    final match = RegExp('filename="?([^"]+)"?').firstMatch(contentDisposition);
    return match?.group(1);
  }

  /// POST /api/documents — multipart. Registers a new record: encrypts the
  /// file, uploads it, writes version 1. [recordNo] must be unique — the
  /// backend returns 403 with statusCode 409 on a duplicate; callers
  /// should regenerate and retry (see SmartUpload's commit flow).
  Future<({int id, String recordNo, int versionId})> create({
    required String recordNo,
    required String title,
    required int documentTypeId,
    required int folderId,
    int? departmentId,
    String? memberNumber,
    String? memberName,
    String? classification,
    int? retentionClassId,
    String? storageProviderId,
    String? storagePrefix,
    List<({String label, String value})>? customFields,
    bool allowDuplicate = false,
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    final formData = FormData.fromMap({
      'recordNo': recordNo,
      'title': title,
      'documentTypeId': '$documentTypeId',
      'folderId': '$folderId',
      if (departmentId != null) 'departmentId': '$departmentId',
      if (memberNumber != null && memberNumber.isNotEmpty) 'memberNumber': memberNumber,
      if (memberName != null && memberName.isNotEmpty) 'memberName': memberName,
      if (classification != null && classification.isNotEmpty) 'classification': classification,
      if (retentionClassId != null) 'retentionClassId': '$retentionClassId',
      if (storageProviderId != null && storageProviderId.isNotEmpty) 'storageProviderId': storageProviderId,
      if (storagePrefix != null && storagePrefix.isNotEmpty) 'storagePrefix': storagePrefix,
      if (customFields != null && customFields.isNotEmpty)
        'customFields': jsonEncode(customFields.map((f) => {'label': f.label, 'value': f.value}).toList()),
      if (allowDuplicate) 'allowDuplicate': 'true',
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName, contentType: DioMediaType.parse(mimeType)),
    });
    final response = await _client.post(Endpoints.documents, data: formData);
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      return (id: json['id'] as int, recordNo: json['recordNo'] as String, versionId: json['versionId'] as int);
    });
  }

  /// POST /api/documents/ocr-preview — stateless, writes nothing. Used by
  /// Smart Upload to populate suggested fields before the user commits.
  Future<OcrPreviewResult> ocrPreview({
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName, contentType: DioMediaType.parse(mimeType)),
    });
    final response = await _client.post(Endpoints.documentsOcrPreview, data: formData);
    return _client.unwrap(response, (data) => OcrPreviewResult.fromJson(data as Map<String, dynamic>));
  }

  /// POST /api/documents/:id/declare-final — starts the retention clock:
  /// sets status='declared_final' and computes retention_due_at from the
  /// document's retention class. No body required.
  Future<void> declareFinal(int id) async {
    final response = await _client.post(Endpoints.documentDeclareFinal('$id'));
    _client.unwrap(response, (_) => null);
  }
}
