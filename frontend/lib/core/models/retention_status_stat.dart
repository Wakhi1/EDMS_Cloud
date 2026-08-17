/// A row from GET /api/reports/retention-status — {retentionClass, total,
/// disposed}. Hand-rolled (no freezed/codegen), same style as CountItem —
/// doesn't fit CountItem's plain label/total shape since it needs a second
/// numeric field.
class RetentionStatusStat {
  const RetentionStatusStat({required this.retentionClass, required this.total, required this.disposed});

  final String retentionClass;
  final int total;
  final int disposed;

  factory RetentionStatusStat.fromJson(Map<String, dynamic> json) {
    return RetentionStatusStat(
      retentionClass: json['retentionClass'] as String,
      total: _asInt(json['total']),
      disposed: _asInt(json['disposed']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
