import '../../models/capacity_stats.dart';
import '../../models/capture_source_stat.dart';
import '../../models/claim_turnaround_point.dart';
import '../../models/count_item.dart';
import '../../models/retention_status_stat.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/reports.routes.js. Every document-based endpoint
/// (byStatus/byDepartment/byCategory/byFolder/byClassification/
/// capturedOverTime/retentionStatus) accepts the same optional filter set;
/// the audit-based ones (auditActions/topUsers/claimTurnaround) accept only
/// from/to. Used by both Phase 1's Dashboard KPIs (silent403, unfiltered)
/// and the Reports module (non-silent, filterable).
class ReportsApi {
  ReportsApi(this._client);

  final ApiClient _client;

  Map<String, dynamic> _documentFilterParams({
    String? from,
    String? to,
    int? departmentId,
    int? documentTypeId,
    int? folderId,
    String? classification,
  }) {
    return {
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
      if (departmentId != null) 'departmentId': departmentId,
      if (documentTypeId != null) 'documentTypeId': documentTypeId,
      if (folderId != null) 'folderId': folderId,
      if (classification != null && classification.isNotEmpty) 'classification': classification,
    };
  }

  Future<List<CountItem>> byStatus({
    bool silent403 = false,
    String? from,
    String? to,
    int? departmentId,
    int? documentTypeId,
    int? folderId,
    String? classification,
  }) async {
    final response = await _client.get(
      Endpoints.reportsByStatus,
      silent403: silent403,
      queryParameters: _documentFilterParams(from: from, to: to, departmentId: departmentId, documentTypeId: documentTypeId, folderId: folderId, classification: classification),
    );
    return _client.unwrapList(response, CountItem.fromStatusJson);
  }

  Future<List<CountItem>> byDepartment({
    bool silent403 = false,
    String? from,
    String? to,
    int? documentTypeId,
    int? folderId,
    String? classification,
  }) async {
    final response = await _client.get(
      Endpoints.reportsByDepartment,
      silent403: silent403,
      queryParameters: _documentFilterParams(from: from, to: to, documentTypeId: documentTypeId, folderId: folderId, classification: classification),
    );
    return _client.unwrapList(response, CountItem.fromDepartmentJson);
  }

  Future<List<CountItem>> byCategory({
    bool silent403 = false,
    String? from,
    String? to,
    int? departmentId,
    int? folderId,
    String? classification,
  }) async {
    final response = await _client.get(
      Endpoints.reportsByCategory,
      silent403: silent403,
      queryParameters: _documentFilterParams(from: from, to: to, departmentId: departmentId, folderId: folderId, classification: classification),
    );
    return _client.unwrapList(response, CountItem.fromCategoryJson);
  }

  Future<List<CountItem>> byFolder({
    bool silent403 = false,
    String? from,
    String? to,
    int? departmentId,
    int? documentTypeId,
    String? classification,
  }) async {
    final response = await _client.get(
      Endpoints.reportsByFolder,
      silent403: silent403,
      queryParameters: _documentFilterParams(from: from, to: to, departmentId: departmentId, documentTypeId: documentTypeId, classification: classification),
    );
    return _client.unwrapList(response, CountItem.fromFolderJson);
  }

  Future<List<CountItem>> byClassification({
    bool silent403 = false,
    String? from,
    String? to,
    int? departmentId,
    int? documentTypeId,
    int? folderId,
  }) async {
    final response = await _client.get(
      Endpoints.reportsByClassification,
      silent403: silent403,
      queryParameters: _documentFilterParams(from: from, to: to, departmentId: departmentId, documentTypeId: documentTypeId, folderId: folderId),
    );
    return _client.unwrapList(response, CountItem.fromClassificationJson);
  }

  /// Deliberately unfiltered — a point-in-time global total.
  Future<CapacityStats> capacity({bool silent403 = false}) async {
    final response = await _client.get(Endpoints.reportsCapacity, silent403: silent403);
    return _client.unwrap(response, (data) => CapacityStats.fromJson(data as Map<String, dynamic>));
  }

  Future<List<CountItem>> capturedOverTime({
    bool silent403 = false,
    String? from,
    String? to,
    int? departmentId,
    int? documentTypeId,
    int? folderId,
    String? classification,
  }) async {
    final response = await _client.get(
      Endpoints.reportsCapturedOverTime,
      silent403: silent403,
      queryParameters: _documentFilterParams(from: from, to: to, departmentId: departmentId, documentTypeId: documentTypeId, folderId: folderId, classification: classification),
    );
    return _client.unwrapList(response, CountItem.fromMonthJson);
  }

  Future<List<CaptureSourceStat>> captureBySource({bool silent403 = false, String? from, String? to}) async {
    final response = await _client.get(
      Endpoints.reportsCaptureBySource,
      silent403: silent403,
      queryParameters: {if (from != null && from.isNotEmpty) 'from': from, if (to != null && to.isNotEmpty) 'to': to},
    );
    return _client.unwrap(response, (data) {
      if (data is! List) return <CaptureSourceStat>[];
      return data.whereType<Map<String, dynamic>>().map(CaptureSourceStat.fromJson).toList(growable: false);
    });
  }

  Future<List<RetentionStatusStat>> retentionStatus({
    bool silent403 = false,
    String? from,
    String? to,
    int? departmentId,
    int? documentTypeId,
    int? folderId,
    String? classification,
  }) async {
    final response = await _client.get(
      Endpoints.reportsRetentionStatus,
      silent403: silent403,
      queryParameters: _documentFilterParams(from: from, to: to, departmentId: departmentId, documentTypeId: documentTypeId, folderId: folderId, classification: classification),
    );
    return _client.unwrap(response, (data) {
      if (data is! List) return <RetentionStatusStat>[];
      return data.whereType<Map<String, dynamic>>().map(RetentionStatusStat.fromJson).toList(growable: false);
    });
  }

  Future<List<ClaimTurnaroundPoint>> claimTurnaround({bool silent403 = false, String? from, String? to}) async {
    final response = await _client.get(
      Endpoints.reportsClaimTurnaround,
      silent403: silent403,
      queryParameters: {if (from != null && from.isNotEmpty) 'from': from, if (to != null && to.isNotEmpty) 'to': to},
    );
    return _client.unwrap(response, (data) {
      if (data is! List) return <ClaimTurnaroundPoint>[];
      return data.whereType<Map<String, dynamic>>().map(ClaimTurnaroundPoint.fromJson).toList(growable: false);
    });
  }

  Future<List<CountItem>> auditActions({bool silent403 = false, String? from, String? to}) async {
    final response = await _client.get(
      Endpoints.reportsAuditActions,
      silent403: silent403,
      queryParameters: {if (from != null && from.isNotEmpty) 'from': from, if (to != null && to.isNotEmpty) 'to': to},
    );
    return _client.unwrapList(response, CountItem.fromAuditActionJson);
  }

  Future<List<CountItem>> topUsers({bool silent403 = false, String? from, String? to}) async {
    final response = await _client.get(
      Endpoints.reportsTopUsers,
      silent403: silent403,
      queryParameters: {if (from != null && from.isNotEmpty) 'from': from, if (to != null && to.isNotEmpty) 'to': to},
    );
    return _client.unwrapList(response, CountItem.fromUserJson);
  }
}
