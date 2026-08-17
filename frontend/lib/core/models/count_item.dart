/// A simple label/count pair, shared by GET /api/reports/by-status
/// ({status,total}) and GET /api/reports/by-department ({department,
/// total}). Hand-rolled (no freezed/codegen) since it's a trivial shape used
/// only for chart/list rendering, not passed around as app state.
class CountItem {
  const CountItem({required this.label, required this.total});

  final String label;
  final int total;

  factory CountItem.fromStatusJson(Map<String, dynamic> json) {
    return CountItem(label: json['status'] as String, total: _asInt(json['total']));
  }

  factory CountItem.fromDepartmentJson(Map<String, dynamic> json) {
    return CountItem(label: (json['department'] as String?) ?? 'Unassigned', total: _asInt(json['total']));
  }

  factory CountItem.fromAuditActionJson(Map<String, dynamic> json) {
    return CountItem(label: json['action'] as String, total: _asInt(json['total']));
  }

  factory CountItem.fromCategoryJson(Map<String, dynamic> json) {
    return CountItem(label: (json['category'] as String?) ?? 'Unclassified', total: _asInt(json['total']));
  }

  factory CountItem.fromFolderJson(Map<String, dynamic> json) {
    return CountItem(label: (json['folder'] as String?) ?? 'Unfiled', total: _asInt(json['total']));
  }

  factory CountItem.fromClassificationJson(Map<String, dynamic> json) {
    return CountItem(label: (json['classification'] as String?) ?? 'Unclassified', total: _asInt(json['total']));
  }

  factory CountItem.fromUserJson(Map<String, dynamic> json) {
    return CountItem(label: (json['userName'] as String?) ?? 'System', total: _asInt(json['total']));
  }

  factory CountItem.fromMonthJson(Map<String, dynamic> json) {
    return CountItem(label: json['month'] as String, total: _asInt(json['total']));
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
