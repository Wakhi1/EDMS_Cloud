import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform_admin/models/branding_history_row.dart';
import '../../../core/platform_admin/models/company_row.dart';
import '../../../core/platform_admin/models/license_row.dart';
import '../../../core/platform_admin/models/platform_audit_row.dart';
import '../../../core/platform_admin/platform_admin_providers.dart';

final companiesListProvider = FutureProvider.autoDispose<List<CompanyRow>>((ref) {
  return ref.watch(platformAdminApiProvider).listCompanies();
});

final companyDetailProvider = FutureProvider.autoDispose.family<({CompanyRow company, List<LicenseRow> licenses, int userCount}), int>(
  (ref, companyId) => ref.watch(platformAdminApiProvider).getCompany(companyId),
);

final companyBrandingHistoryProvider = FutureProvider.autoDispose.family<List<BrandingHistoryRow>, int>(
  (ref, companyId) => ref.watch(platformAdminApiProvider).brandingHistory(companyId),
);

final companyAuditProvider = FutureProvider.autoDispose.family<List<PlatformAuditRow>, int>(
  (ref, companyId) => ref.watch(platformAdminApiProvider).companyAudit(companyId),
);
