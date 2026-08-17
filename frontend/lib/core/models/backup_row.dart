/// A row from GET /api/backup — hand-rolled, simple display shape, never
/// edited or posted back (same convention as CaptureBatchRow).
class BackupRow {
  const BackupRow({
    required this.id,
    required this.fileKey,
    this.sizeBytes,
    required this.storageProvider,
    required this.status,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
    this.createdBy,
  });

  final int id;
  final String fileKey;
  final int? sizeBytes;
  final String storageProvider;
  final String status; // 'running' | 'completed' | 'failed'
  final String? errorMessage;
  final String createdAt;
  final String? completedAt;
  final String? createdBy;

  factory BackupRow.fromJson(Map<String, dynamic> json) {
    return BackupRow(
      id: _asInt(json['id']),
      fileKey: json['file_key'] as String,
      sizeBytes: json['size_bytes'] == null ? null : _asInt(json['size_bytes']),
      storageProvider: json['storage_provider'] as String,
      status: json['status'] as String,
      errorMessage: json['error_message'] as String?,
      createdAt: json['created_at'] as String,
      completedAt: json['completed_at'] as String?,
      createdBy: json['created_by'] as String?,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}
