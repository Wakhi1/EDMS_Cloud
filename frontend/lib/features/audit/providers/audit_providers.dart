import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/audit_log_row.dart';

class AuditFilters {
  const AuditFilters({this.action, this.recordType, this.q = '', this.from, this.to});

  final String? action;
  final String? recordType;
  final String q;
  final String? from; // yyyy-MM-dd
  final String? to; // yyyy-MM-dd

  AuditFilters copyWith({
    String? Function()? action,
    String? Function()? recordType,
    String? q,
    String? Function()? from,
    String? Function()? to,
  }) {
    return AuditFilters(
      action: action != null ? action() : this.action,
      recordType: recordType != null ? recordType() : this.recordType,
      q: q ?? this.q,
      from: from != null ? from() : this.from,
      to: to != null ? to() : this.to,
    );
  }
}

final auditFiltersProvider = StateProvider<AuditFilters>((ref) => const AuditFilters());

final auditLogProvider = FutureProvider.autoDispose<List<AuditLogRow>>((ref) {
  final f = ref.watch(auditFiltersProvider);
  return ref.watch(auditApiProvider).list(action: f.action, recordType: f.recordType, q: f.q, from: f.from, to: f.to);
});

final auditRecordTypesProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(auditApiProvider).recordTypes();
});

final auditVerifyChainProvider = FutureProvider.autoDispose<({bool valid, int? brokenAtId, int entries})>((ref) {
  return ref.watch(auditApiProvider).verifyChain();
});
