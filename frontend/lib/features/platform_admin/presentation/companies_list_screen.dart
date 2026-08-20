import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/platform_admin/models/company_row.dart';
import '../../../core/platform_admin/platform_admin_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/result_dialog.dart';
import '../../../core/widgets/status_chip.dart';
import '../providers/platform_admin_data_providers.dart';
import 'create_company_dialog.dart';

/// /platform-admin — every licensed client company, with a "New company"
/// action. Clicking a row opens company_detail_screen.dart.
class CompaniesListScreen extends ConsumerWidget {
  const CompaniesListScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<
        ({
          String companyCode,
          String name,
          String? registrationNo,
          String? taxId,
          String? contactName,
          String? contactEmail,
          String? contactPhone,
        })>(context: context, builder: (_) => const CreateCompanyDialog());
    if (result == null) return;

    try {
      await ref.read(platformAdminApiProvider).createCompany(
            companyCode: result.companyCode,
            name: result.name,
            registrationNo: result.registrationNo,
            taxId: result.taxId,
            contactName: result.contactName,
            contactEmail: result.contactEmail,
            contactPhone: result.contactPhone,
          );
      ref.invalidate(companiesListProvider);
      if (context.mounted) await ResultDialog.showSuccess(context, 'Company created.');
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(companiesListProvider);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Companies', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              ElevatedButton.icon(onPressed: () => _create(context, ref), icon: const Icon(Icons.add), label: const Text('New company')),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: companiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(message: error is ApiException ? error.message : '$error', onRetry: () => ref.invalidate(companiesListProvider)),
              data: (companies) {
                if (companies.isEmpty) return const EmptyState(message: 'No companies yet — create the first one.');
                return SingleChildScrollView(
                  child: Column(
                    children: [for (final c in companies) _CompanyRow(company: c)],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyRow extends StatelessWidget {
  const _CompanyRow({required this.company});

  final CompanyRow company;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: () => context.go(RoutePaths.platformAdminCompanyFor('${company.id}')),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tokens.line))),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  Text(company.companyCode, style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: StatusChip(
                company.status,
                tone: company.status == 'active' ? StatusTone.ok : (company.status == 'suspended' ? StatusTone.bad : StatusTone.plain),
              ),
            ),
            Expanded(
              flex: 3,
              child: company.currentLicenseType == null
                  ? Text('No license', style: TextStyle(fontSize: 12, color: tokens.ink2))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${company.currentLicenseType} · ${company.currentLicenseStatus}', style: const TextStyle(fontSize: 12)),
                        if (company.currentLicenseExpiresAt != null)
                          Text('expires ${company.currentLicenseExpiresAt}', style: TextStyle(fontSize: 11, color: tokens.ink2)),
                      ],
                    ),
            ),
            Icon(Icons.chevron_right, color: tokens.ink2),
          ],
        ),
      ),
    );
  }
}
