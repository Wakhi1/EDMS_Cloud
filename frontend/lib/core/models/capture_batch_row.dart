/// A row from GET /api/capture-batches (or the detail view's batch fields)
/// — hand-rolled (no freezed/codegen), same convention as
/// CaptureBatchSummary: simple display shape, never edited or posted back.
class CaptureBatchRow {
  const CaptureBatchRow({
    required this.id,
    required this.batchNo,
    required this.source,
    required this.status,
    required this.pages,
    required this.documents,
    required this.successRate,
    this.startedAt,
    this.completedAt,
    this.createdBy,
  });

  final int id;
  final String batchNo;
  final String source;
  final String status;
  final int pages;
  final int documents;
  final double successRate;
  final String? startedAt;
  final String? completedAt;
  final String? createdBy;

  factory CaptureBatchRow.fromJson(Map<String, dynamic> json) {
    return CaptureBatchRow(
      id: _asInt(json['id']),
      batchNo: json['batch_no'] as String,
      source: json['source'] as String,
      status: json['status'] as String,
      pages: _asInt(json['pages']),
      documents: _asInt(json['documents']),
      successRate: _asDouble(json['success_rate']),
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      createdBy: json['created_by'] as String?,
    );
  }
}

class CaptureBatchItem {
  const CaptureBatchItem({
    required this.id,
    required this.sourceFileName,
    required this.status,
    this.errorMessage,
    this.documentId,
    this.recordNo,
    this.title,
  });

  final int id;
  final String sourceFileName;
  final String status;
  final String? errorMessage;
  final int? documentId;
  final String? recordNo;
  final String? title;

  factory CaptureBatchItem.fromJson(Map<String, dynamic> json) {
    return CaptureBatchItem(
      id: _asInt(json['id']),
      sourceFileName: json['source_file_name'] as String,
      status: json['status'] as String,
      errorMessage: json['error_message'] as String?,
      documentId: json['document_id'] == null ? null : _asInt(json['document_id']),
      recordNo: json['record_no'] as String?,
      title: json['title'] as String?,
    );
  }
}

class CaptureBatchDetail {
  const CaptureBatchDetail({required this.batch, required this.items});

  final CaptureBatchRow batch;
  final List<CaptureBatchItem> items;

  factory CaptureBatchDetail.fromJson(Map<String, dynamic> json) {
    return CaptureBatchDetail(
      batch: CaptureBatchRow.fromJson(json),
      items: (json['items'] as List).cast<Map<String, dynamic>>().map(CaptureBatchItem.fromJson).toList(),
    );
  }
}

class CaptureConnectorStatus {
  const CaptureConnectorStatus({required this.id, required this.name, required this.status, this.lastSyncAt});

  final String id;
  final String name;
  final String status;
  final String? lastSyncAt;

  factory CaptureConnectorStatus.fromJson(Map<String, dynamic> json) {
    return CaptureConnectorStatus(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      lastSyncAt: json['last_sync_at'] as String?,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}
