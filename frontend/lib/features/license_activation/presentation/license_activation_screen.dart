import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/branding_provider.dart';
import '../../../core/license/license_gate_provider.dart';
import '../../../core/models/company_branding.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/company_logo_box.dart';
import '../../../core/widgets/error_banner.dart';

/// Shown instead of the login screen whenever this deployment doesn't
/// currently hold an active license — go_router's redirect (see
/// core/router/app_router.dart) forces every route here until
/// [LicenseGateState.active] is true, then forwards straight to /login on
/// its own (this screen never navigates itself). Mirrors LoginScreen's
/// split hero/form layout so the two feel like one continuous flow.
class LicenseActivationScreen extends ConsumerStatefulWidget {
  const LicenseActivationScreen({super.key});

  @override
  ConsumerState<LicenseActivationScreen> createState() => _LicenseActivationScreenState();
}

class _LicenseActivationScreenState extends ConsumerState<LicenseActivationScreen> {
  final _keyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(licenseGateControllerProvider.notifier).activate(_keyController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final gateState = ref.watch(licenseGateControllerProvider);

    return Scaffold(
      backgroundColor: tokens.paper,
      body: Row(
        children: [
          if (wide) Expanded(flex: 5, child: _HeroPanel(tokens: tokens)),
          Expanded(
            flex: 4,
            child: Container(
              color: tokens.paper,
              padding: EdgeInsets.symmetric(horizontal: wide ? 34 : 20, vertical: wide ? 42 : 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Activate this deployment', style: textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(
                            'This installation doesn\'t have an active license yet. Enter the license key '
                            'DocSecure emailed your organization to activate it.',
                            style: textTheme.bodyMedium?.copyWith(color: tokens.ink2),
                          ),
                          const SizedBox(height: 16),
                          if (gateState.error != null) ...[
                            ErrorBanner(gateState.error!),
                            const SizedBox(height: 14),
                          ],
                          Text('LICENSE KEY', style: textTheme.labelMedium),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _keyController,
                            enabled: !gateState.submitting,
                            autofocus: true,
                            decoration: const InputDecoration(hintText: 'e.g. 8204d187-9133-4bff-bda1-268f77b1d88c'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your license key.' : null,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: gateState.submitting ? null : _submit,
                              child: gateState.submitting
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('ACTIVATE'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: TextButton(
                              onPressed: gateState.submitting
                                  ? null
                                  : () => ref.read(licenseGateControllerProvider.notifier).recheck(),
                              child: const Text('Already activated? Check again'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends ConsumerWidget {
  const _HeroPanel({required this.tokens});

  final PspfTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final branding = ref.watch(companyBrandingProvider).valueOrNull ?? CompanyBranding.fallback;
    return Container(
      color: tokens.surf2,
      padding: const EdgeInsets.fromLTRB(46, 42, 46, 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CompanyLogoBox(),
          const SizedBox(height: 22),
          Text('KINGDOM OF ESWATINI', style: textTheme.labelMedium?.copyWith(letterSpacing: 0.22, color: tokens.ink3)),
          const SizedBox(height: 8),
          SizedBox(width: 320, child: Text(branding.name, style: textTheme.displaySmall)),
          const SizedBox(height: 18),
          SizedBox(
            width: 380,
            child: Text(
              'Electronic Document & Records Management System, licensed and supported by DocSecure Eswatini.',
              style: textTheme.bodyLarge?.copyWith(color: tokens.ink2),
            ),
          ),
          const Spacer(),
          Text(
            'This deployment checks in with DocSecure\'s licensing platform to confirm it\'s authorized to run.',
            style: textTheme.bodySmall?.copyWith(color: tokens.ink3),
          ),
        ],
      ),
    );
  }
}
