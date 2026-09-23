import 'count_item.dart';

/// Role-shaped headline figures from GET /api/dashboard/summary
/// (backend/routes/dashboard.routes.js). A section the caller's role can't
/// see is null — the Dashboard hides it rather than showing an error.
/// Hand-rolled (no freezed/codegen), same style as CapacityStats.
class DashboardSummary {
  const DashboardSummary({required this.documents, required this.folders, required this.storage});

  final DocumentStats? documents;
  final FolderStats? folders;
  final StorageStats? storage;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? section(String key) => json[key] is Map ? Map<String, dynamic>.from(json[key] as Map) : null;
    final documents = section('documents');
    final folders = section('folders');
    final storage = section('storage');
    return DashboardSummary(
      documents: documents == null ? null : DocumentStats.fromJson(documents),
      folders: folders == null ? null : FolderStats.fromJson(folders),
      storage: storage == null ? null : StorageStats.fromJson(storage),
    );
  }
}

class DocumentStats {
  const DocumentStats({
    required this.total,
    required this.live,
    required this.mine,
    required this.createdThisMonth,
    required this.byStatus,
    required this.byType,
    required this.fileCount,
    required this.currentFileCount,
    required this.pageCount,
    required this.pagesEstimated,
    required this.uncountedFiles,
    required this.currentBytes,
  });

  final int total;
  final int live;
  final int mine;
  final int createdThisMonth;
  final List<CountItem> byStatus;
  final List<CountItem> byType;
  final int fileCount;
  final int currentFileCount;
  final int pageCount;
  final bool pagesEstimated;
  final int uncountedFiles;
  final int currentBytes;

  int statusCount(String status) => byStatus.where((c) => c.label == status).fold(0, (s, c) => s + c.total);

  factory DocumentStats.fromJson(Map<String, dynamic> json) {
    List<CountItem> counts(String key, String labelKey) => [
      for (final row in (json[key] as List? ?? const [])) CountItem(label: '${(row as Map)[labelKey]}', total: _asInt(row['total'])),
    ];
    return DocumentStats(
      total: _asInt(json['total']),
      live: _asInt(json['live']),
      mine: _asInt(json['mine']),
      createdThisMonth: _asInt(json['createdThisMonth']),
      byStatus: counts('byStatus', 'status'),
      byType: counts('byType', 'label'),
      fileCount: _asInt(json['fileCount']),
      currentFileCount: _asInt(json['currentFileCount']),
      pageCount: _asInt(json['pageCount']),
      pagesEstimated: json['pagesEstimated'] == true,
      uncountedFiles: _asInt(json['uncountedFiles']),
      currentBytes: _asInt(json['currentBytes']),
    );
  }
}

class FolderStats {
  const FolderStats({required this.total, required this.topLevel, required this.empty});

  final int total;
  final int topLevel;
  final int empty;

  factory FolderStats.fromJson(Map<String, dynamic> json) =>
      FolderStats(total: _asInt(json['total']), topLevel: _asInt(json['topLevel']), empty: _asInt(json['empty']));
}

class StorageStats {
  const StorageStats({required this.usedBytes, required this.objectCount, required this.capacityBytes, required this.locations});

  final int usedBytes;
  final int objectCount;
  final int capacityBytes;
  final List<StorageLocationStat> locations;

  factory StorageStats.fromJson(Map<String, dynamic> json) => StorageStats(
    usedBytes: _asInt(json['usedBytes']),
    objectCount: _asInt(json['objectCount']),
    capacityBytes: _asInt(json['capacityBytes']),
    locations: [for (final row in (json['locations'] as List? ?? const [])) StorageLocationStat.fromJson(Map<String, dynamic>.from(row as Map))],
  );
}

class StorageLocationStat {
  const StorageLocationStat({
    required this.provider,
    required this.name,
    required this.status,
    required this.active,
    required this.usedBytes,
    required this.objectCount,
    required this.capacityBytes,
  });

  final String provider;
  final String name;
  final String status;
  final bool active;
  final int usedBytes;
  final int objectCount;

  /// 0 when no capacity is configured for this location.
  final int capacityBytes;

  double get usedFraction => capacityBytes <= 0 ? 0 : (usedBytes / capacityBytes).clamp(0, 1).toDouble();

  factory StorageLocationStat.fromJson(Map<String, dynamic> json) => StorageLocationStat(
    provider: '${json['provider']}',
    name: '${json['name']}',
    status: '${json['status']}',
    active: json['active'] == true,
    usedBytes: _asInt(json['usedBytes']),
    objectCount: _asInt(json['objectCount']),
    capacityBytes: _asInt(json['capacityBytes']),
  );
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}
