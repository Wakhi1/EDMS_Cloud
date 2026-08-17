/// Storage usage vs. the admin-configured capacity, from
/// GET /api/reports/capacity. Hand-rolled (no freezed/codegen), same style
/// as CountItem — a trivial shape used only for one Dashboard KPI card.
class CapacityStats {
  const CapacityStats({
    required this.usedBytes,
    required this.capacityBytes,
    required this.objectCount,
    required this.documentCount,
  });

  final int usedBytes;
  final int capacityBytes;
  final int objectCount;
  final int documentCount;

  double get usedFraction => capacityBytes <= 0 ? 0 : (usedBytes / capacityBytes).clamp(0, 1).toDouble();

  factory CapacityStats.fromJson(Map<String, dynamic> json) {
    return CapacityStats(
      usedBytes: _asInt(json['usedBytes']),
      capacityBytes: _asInt(json['capacityBytes']),
      objectCount: _asInt(json['objectCount']),
      documentCount: _asInt(json['documentCount']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
