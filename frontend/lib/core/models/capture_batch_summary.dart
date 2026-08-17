/// A row from GET /api/integrations/capture-batches/summary — aggregate
/// throughput per intake source. Hand-rolled (no freezed/codegen): a
/// trivial chart/list-display shape from one GROUP BY query, never edited
/// or passed to a dialog, same class as CountItem.
class CaptureBatchSummary {
  const CaptureBatchSummary({
    required this.source,
    required this.batches,
    required this.totalPages,
    required this.totalDocuments,
    required this.avgSuccessRate,
  });

  final String source;
  final int batches;
  final int totalPages;
  final int totalDocuments;
  final double avgSuccessRate;

  factory CaptureBatchSummary.fromJson(Map<String, dynamic> json) {
    return CaptureBatchSummary(
      source: json['source'] as String,
      batches: _asInt(json['batches']),
      totalPages: _asInt(json['total_pages']),
      totalDocuments: _asInt(json['total_documents']),
      avgSuccessRate: _asDouble(json['avg_success_rate']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
