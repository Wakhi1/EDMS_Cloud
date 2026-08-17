import 'package:dio/dio.dart';

import '../../models/audit_log_row.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/audit.routes.js.
class AuditApi {
  AuditApi(this._client);

  final ApiClient _client;

  Future<List<AuditLogRow>> list({String? action, String? recordType, String? q, String? from, String? to}) async {
    final response = await _client.get(
      Endpoints.audit,
      queryParameters: {
        if (action != null && action.isNotEmpty) 'action': action,
        if (recordType != null && recordType.isNotEmpty) 'recordType': recordType,
        if (q != null && q.isNotEmpty) 'q': q,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
    );
    return _client.unwrapList(response, AuditLogRow.fromJson);
  }

  /// Real (non-guessed) values for the record-type filter dropdown.
  Future<List<String>> recordTypes() async {
    final response = await _client.get(Endpoints.auditRecordTypes);
    return _client.unwrap(response, (data) => (data as List).cast<String>());
  }

  /// GET /api/audit/export.csv — the backend sends a raw text/csv body
  /// (`res.send(header + body)`), NOT the {success,data} envelope, so bytes
  /// are read straight off response.data like DocumentsApi.content() does.
  /// Now respects the same filters as [list] (previously always exported
  /// the unfiltered top rows regardless of the on-screen filters).
  Future<({List<int> bytes, String fileName})> exportCsv({String? action, String? recordType, String? q, String? from, String? to}) async {
    final response = await _client.get(
      Endpoints.auditExportCsv,
      queryParameters: {
        if (action != null && action.isNotEmpty) 'action': action,
        if (recordType != null && recordType.isNotEmpty) 'recordType': recordType,
        if (q != null && q.isNotEmpty) 'q': q,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return (bytes: (response.data as List<int>?) ?? const [], fileName: 'audit-export.csv');
  }

  Future<({bool valid, int? brokenAtId, int entries})> verifyChain() async {
    final response = await _client.get(Endpoints.auditVerifyChain);
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      return (
        valid: json['valid'] as bool,
        brokenAtId: json['brokenAtId'] as int?,
        entries: json['entries'] as int,
      );
    });
  }
}
