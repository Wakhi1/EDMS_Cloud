import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/platform_admin/models/company_row.dart';
import '../../../core/platform_admin/models/license_row.dart';
import '../../../core/platform_admin/platform_admin_providers.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/result_dialog.dart';
import '../../../core/widgets/status_chip.dart';
import '../providers/platform_admin_data_providers.dart';
import 'create_admin_user_dialog.dart';
import 'issue_license_dialog.dart';

/// /platform-admin/companies/:id — identity, license lifecycle, branding
/// theme, and the DocSecore-staff action trail for one company.
class CompanyDetailScreen extends ConsumerWidget {
  const CompanyDetailScreen({super.key, required this.companyId});

  final int companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(companyDetailProvider(companyId));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ErrorState(message: error is ApiException ? error.message : '$error', onRetry: () => ref.invalidate(companyDetailProvider(companyId))),
      ),
      data: (detail) => SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(company: detail.company, userCount: detail.userCount),
            const SizedBox(height: 24),
            _LicenseSection(companyId: companyId, licenses: detail.licenses),
            const SizedBox(height: 24),
            _BrandingSection(company: detail.company),
            const SizedBox(height: 24),
            _BrandingHistorySection(companyId: companyId),
            const SizedBox(height: 24),
            _AuditSection(companyId: companyId),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.labelSmall),
                const Spacer(),
                if (action != null) action!,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}

class _HeaderSection extends ConsumerWidget {
  const _HeaderSection({required this.company, required this.userCount});

  final CompanyRow company;
  final int userCount;

  Future<void> _toggleStatus(BuildContext context, WidgetRef ref) async {
    final suspending = company.status == 'active';
    final confirmed = await ConfirmDialog.show(
      context,
      title: '${suspending ? "Suspend" : "Activate"} ${company.name}?',
      body: suspending ? 'This immediately signs out every user at this company and blocks new sign-ins.' : null,
      okLabel: suspending ? 'Suspend' : 'Activate',
      danger: suspending,
    );
    if (confirmed == null) return;

    try {
      await ref.read(platformAdminApiProvider).setCompanyStatus(company.id, suspending ? 'suspended' : 'active');
      ref.invalidate(companyDetailProvider(company.id));
      ref.invalidate(companiesListProvider);
      if (context.mounted) await ResultDialog.showSuccess(context, 'Company ${suspending ? "suspended" : "activated"}.');
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  Future<void> _createAdminUser(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String fullName, String email, String password})>(
      context: context,
      builder: (_) => const CreateAdminUserDialog(),
    );
    if (result == null) return;

    try {
      await ref.read(platformAdminApiProvider).createAdminUser(company.id, fullName: result.fullName, email: result.email, password: result.password);
      ref.invalidate(companyDetailProvider(company.id));
      if (context.mounted) {
        await ResultDialog.showSuccess(context, '${result.fullName} can now sign in to the ${company.name} EDMS with company code "${company.companyCode}".');
      }
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(company.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 10),
                        StatusChip(company.status, tone: company.status == 'active' ? StatusTone.ok : StatusTone.bad),
                      ],
                    ),
                    Text('Code: ${company.companyCode}  ·  $userCount user(s)', style: TextStyle(fontSize: 12.5, color: tokens.ink2)),
                  ],
                ),
              ),
              OutlinedButton(onPressed: () => _createAdminUser(context, ref), child: const Text('Create admin user')),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _toggleStatus(context, ref),
                style: company.status == 'active' ? OutlinedButton.styleFrom(foregroundColor: tokens.bad, side: BorderSide(color: tokens.bad)) : null,
                child: Text(company.status == 'active' ? 'Suspend' : 'Activate'),
              ),
            ],
          ),
          if (company.contactName != null || company.contactEmail != null || company.contactPhone != null) ...[
            const SizedBox(height: 10),
            Text(
              [company.contactName, company.contactEmail, company.contactPhone].where((s) => s != null && s.isNotEmpty).join('  ·  '),
              style: TextStyle(fontSize: 12, color: tokens.ink2),
            ),
          ],
        ],
      ),
    );
  }
}

class _LicenseSection extends ConsumerWidget {
  const _LicenseSection({required this.companyId, required this.licenses});

  final int companyId;
  final List<LicenseRow> licenses;

  Future<void> _issue(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String licenseType, DateTime expiresAt, int? maxUsers, int? storageQuotaBytes})>(
      context: context,
      builder: (_) => const IssueLicenseDialog(),
    );
    if (result == null) return;

    try {
      await ref.read(platformAdminApiProvider).issueLicense(
            companyId: companyId,
            licenseType: result.licenseType,
            expiresAt: result.expiresAt,
            maxUsers: result.maxUsers,
            storageQuotaBytes: result.storageQuotaBytes,
          );
      ref.invalidate(companyDetailProvider(companyId));
      ref.invalidate(companiesListProvider);
      if (context.mounted) await ResultDialog.showSuccess(context, 'License issued.');
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref, LicenseRow license) async {
    final confirmed = await ConfirmDialog.show(context, title: 'Revoke this ${license.licenseType} license?', okLabel: 'Revoke', danger: true);
    if (confirmed == null) return;

    try {
      await ref.read(platformAdminApiProvider).revokeLicense(license.id);
      ref.invalidate(companyDetailProvider(companyId));
      if (context.mounted) await ResultDialog.showSuccess(context, 'License revoked.');
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  Future<void> _validate(BuildContext context, WidgetRef ref, LicenseRow license) async {
    try {
      final result = await ref.read(platformAdminApiProvider).validateLicense(license.id);
      if (context.mounted) {
        if (result.valid) {
          await ResultDialog.showSuccess(context, 'Signature verified — this license token is authentic and unmodified.');
        } else {
          await ResultDialog.showError(context, 'Verification failed: ${result.result}');
        }
      }
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    return _SectionCard(
      title: 'LICENSES',
      action: OutlinedButton(onPressed: () => _issue(context, ref), child: const Text('Issue license')),
      child: licenses.isEmpty
          ? const EmptyState(message: 'No license issued yet.')
          : Column(
              children: [
                for (final l in licenses)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.line))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(l.licenseType, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(width: 8),
                                  StatusChip(l.status, tone: l.status == 'active' ? StatusTone.ok : (l.status == 'expired' || l.status == 'revoked' ? StatusTone.bad : StatusTone.warn)),
                                ],
                              ),
                              Text('issued ${l.issuedAt}  ·  expires ${l.expiresAt}', style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
                              if (l.revokeReason != null) Text('revoked: ${l.revokeReason}', style: TextStyle(fontSize: 11.5, color: tokens.bad)),
                            ],
                          ),
                        ),
                        TextButton(onPressed: () => _validate(context, ref, l), child: const Text('Validate')),
                        if (l.status == 'active')
                          TextButton(
                            onPressed: () => _revoke(context, ref, l),
                            style: TextButton.styleFrom(foregroundColor: tokens.bad),
                            child: const Text('Revoke'),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _BrandingSection extends ConsumerStatefulWidget {
  const _BrandingSection({required this.company});

  final CompanyRow company;

  @override
  ConsumerState<_BrandingSection> createState() => _BrandingSectionState();
}

class _BrandingSectionState extends ConsumerState<_BrandingSection> {
  late final _primaryController = TextEditingController(text: widget.company.themePrimaryColor);
  late final _secondaryController = TextEditingController(text: widget.company.themeSecondaryColor);
  late final _accentController = TextEditingController(text: widget.company.themeAccentColor);
  late final _domainController = TextEditingController(text: widget.company.customDomain);

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _accentController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await ref.read(platformAdminApiProvider).updateTheme(
            widget.company.id,
            primaryColor: _primaryController.text.trim().isEmpty ? null : _primaryController.text.trim(),
            secondaryColor: _secondaryController.text.trim().isEmpty ? null : _secondaryController.text.trim(),
            accentColor: _accentController.text.trim().isEmpty ? null : _accentController.text.trim(),
            customDomain: _domainController.text.trim().isEmpty ? null : _domainController.text.trim(),
          );
      ref.invalidate(companyDetailProvider(widget.company.id));
      ref.invalidate(companyBrandingHistoryProvider(widget.company.id));
      if (mounted) await ResultDialog.showSuccess(context, 'Branding updated.');
    } on ApiException catch (e) {
      if (mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'BRANDING (white-label theme)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logo/favicon upload isn\'t wired up in this UI yet — theme colors and custom domain only.',
            style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _primaryController, decoration: const InputDecoration(labelText: 'Primary color (#RRGGBB)'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _secondaryController, decoration: const InputDecoration(labelText: 'Secondary color'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _accentController, decoration: const InputDecoration(labelText: 'Accent color'))),
            ],
          ),
          const SizedBox(height: 10),
          TextField(controller: _domainController, decoration: const InputDecoration(labelText: 'Custom domain (optional)')),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: ElevatedButton(onPressed: _save, child: const Text('Save branding'))),
        ],
      ),
    );
  }
}

class _BrandingHistorySection extends ConsumerWidget {
  const _BrandingHistorySection({required this.companyId});

  final int companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final historyAsync = ref.watch(companyBrandingHistoryProvider(companyId));
    return _SectionCard(
      title: 'BRANDING CHANGE HISTORY',
      child: historyAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('$e', style: TextStyle(color: tokens.bad)),
        data: (rows) => rows.isEmpty
            ? const EmptyState(message: 'No branding changes yet.')
            : Column(
                children: [
                  for (final r in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${r.changedAt}  ${r.changedField}: ${r.oldValue ?? "—"} → ${r.newValue ?? "—"}  (${r.changedByName ?? "unknown"})',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _AuditSection extends ConsumerWidget {
  const _AuditSection({required this.companyId});

  final int companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final auditAsync = ref.watch(companyAuditProvider(companyId));
    return _SectionCard(
      title: 'PLATFORM ADMIN ACTIVITY',
      child: auditAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('$e', style: TextStyle(color: tokens.bad)),
        data: (rows) => rows.isEmpty
            ? const EmptyState(message: 'No activity yet.')
            : Column(
                children: [
                  for (final r in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${r.createdAt}  ${r.action}${r.detail != null ? " — ${r.detail}" : ""}  (${r.platformAdminName ?? "unknown"})',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
