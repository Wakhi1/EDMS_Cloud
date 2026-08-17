import 'package:dio/dio.dart';

import '../../models/capture_batch_row.dart';
import '../../models/capture_batch_summary.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/capture.routes.js.
class CaptureBatchesApi {
  CaptureBatchesApi(this._client);

  final ApiClient _client;

  Future<List<CaptureBatchSummary>> summary() async {
    final response = await _client.get(Endpoints.captureBatchesSummary);
    return _client.unwrapList(response, CaptureBatchSummary.fromJson);
  }

  Future<List<CaptureBatchRow>> list({String? source, String? status, String? from, String? to}) async {
    final response = await _client.get(
      Endpoints.captureBatches,
      queryParameters: {'source': ?source, 'status': ?status, 'from': ?from, 'to': ?to},
    );
    return _client.unwrapList(response, CaptureBatchRow.fromJson);
  }

  Future<CaptureBatchDetail> detail(int id) async {
    final response = await _client.get(Endpoints.captureBatchById('$id'));
    return _client.unwrap(response, (data) => CaptureBatchDetail.fromJson(data as Map<String, dynamic>));
  }

  Future<List<CaptureConnectorStatus>> connectorStatus() async {
    final response = await _client.get(Endpoints.captureBatchesConnectorStatus);
    return _client.unwrapList(response, CaptureConnectorStatus.fromJson);
  }

  /// POST /api/capture-batches/upload — multipart, multiple files. [source]
  /// is 'manual_upload' or 'device_upload'.
  Future<({int batchId, String batchNo, int total, int succeeded, String status})> upload({
    required List<({List<int> bytes, String fileName, String mimeType})> files,
    required String source,
    required int folderId,
  }) async {
    final formData = FormData.fromMap({
      'source': source,
      'folderId': '$folderId',
      'files': [for (final f in files) MultipartFile.fromBytes(f.bytes, filename: f.fileName, contentType: DioMediaType.parse(f.mimeType))],
    });
    final response = await _client.post(Endpoints.captureBatchesUpload, data: formData);
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      return (
        batchId: json['batchId'] as int,
        batchNo: json['batchNo'] as String,
        total: json['total'] as int,
        succeeded: json['succeeded'] as int,
        status: json['status'] as String,
      );
    });
  }

  /// Retroactive manual stats-entry (no file upload) — see
  /// capture.routes.js's POST / doc comment for when this is used instead
  /// of [upload].
  Future<void> recordBatch({
    required String batchNo,
    required String source,
    required int pages,
    required int documents,
    required double successRate,
  }) async {
    final response = await _client.post(
      Endpoints.captureBatches,
      data: {'batchNo': batchNo, 'source': source, 'pages': pages, 'documents': documents, 'successRate': successRate},
    );
    _client.unwrap(response, (_) => null);
  }

  /// GET /api/capture-batches/export.csv — raw text/csv body, not the
  /// {success,data} envelope, same pattern as AuditApi.exportCsv().
  Future<({List<int> bytes, String fileName})> exportCsv() async {
    final response = await _client.get(
      Endpoints.captureBatchesExportCsv,
      options: Options(responseType: ResponseType.bytes),
    );
    return (bytes: (response.data as List<int>?) ?? const [], fileName: 'capture-batches-export.csv');
  }
}
