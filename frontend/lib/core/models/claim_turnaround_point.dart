/// A row from GET /api/reports/claim-turnaround ({month,
/// avg_days_to_first_decision}) — hand-rolled, chart-only shape, same
/// rationale as [CountItem]: not passed around as app state.
class ClaimTurnaroundPoint {
  const ClaimTurnaroundPoint({required this.month, required this.avgDaysToFirstDecision});

  final String month;
  final double avgDaysToFirstDecision;

  factory ClaimTurnaroundPoint.fromJson(Map<String, dynamic> json) {
    return ClaimTurnaroundPoint(
      month: json['month'] as String,
      avgDaysToFirstDecision: _asDouble(json['avg_days_to_first_decision']),
    );
  }

  // mysql2 returns ROUND(AVG(...)) as a string, not a number — same
  // stringly-typed-aggregate class of bug found and fixed in
  // versions.routes.js's version_no during Phase 3.
  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
