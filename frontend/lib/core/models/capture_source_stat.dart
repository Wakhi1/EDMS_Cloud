/// A row from GET /api/reports/capture-by-source — {source, total,
/// avgSuccessRate}. Hand-rolled (no freezed/codegen), same style as
/// CountItem — doesn't fit CountItem's plain label/total shape since it
/// needs a second numeric field.
class CaptureSourceStat {
  const CaptureSourceStat({required this.source, required this.total, required this.avgSuccessRate});

  final String source;
  final int total;
  final double avgSuccessRate;

  factory CaptureSourceStat.fromJson(Map<String, dynamic> json) {
    return CaptureSourceStat(
      source: (json['source'] as String).replaceAll('_', ' '),
      total: _asInt(json['total']),
      avgSuccessRate: _asDouble(json['avgSuccessRate']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
