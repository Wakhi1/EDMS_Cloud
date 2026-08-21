import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/branding/branding_provider.dart';
import '../../../core/models/company_branding.dart';
import '../../../core/models/system_setting_row.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/hex_color.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [Tab(text: 'System Settings'), Tab(text: 'Profile'), Tab(text: 'Appearance')],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_SystemSettingsTab(), _ProfileTab(), _AppearanceTab()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Boolean-shaped settings (`'true'`/`'false'`) render as a Switch, applied
/// immediately; everything else opens a value-entry dialog — this app's
/// settings are a small fixed set (watermarking, redaction, export limit,
/// confidential-reason, backup schedule), not an open-ended key/value store.
///
/// GET /api/settings is gated server-side to System Administrator / Records
/// Manager only. Every authenticated user reaches this screen for the
/// Profile/Appearance tabs, and TabBarView builds all three tab widgets up
/// front — so without this client-side role check, any other role would
/// trigger a 403 on screen load and get bounced to Access Denied just for
/// opening Settings, the same "auxiliary widget's own API call" bug class
/// documented for the old Smart Upload screen.
const _kSystemSettingsRoles = {'System Administrator', 'Records Manager'};

class _SystemSettingsTab extends ConsumerWidget {
  const _SystemSettingsTab();

  bool _isBool(String value) => value == 'true' || value == 'false';

  Future<void> _toggle(BuildContext context, WidgetRef ref, SystemSettingRow row) async {
    try {
      await ref.read(settingsApiProvider).update(row.key, row.value == 'true' ? 'false' : 'true');
      ref.invalidate(systemSettingsListProvider);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _editValue(BuildContext context, WidgetRef ref, SystemSettingRow row) async {
    final value = await ConfirmDialog.show(
      context,
      title: 'Edit ${row.key}',
      body: row.description,
      fieldLabel: 'Value',
      initialFieldValue: row.value,
      okLabel: 'Save',
    );
    if (value == null || value.trim().isEmpty) return;

    try {
      await ref.read(settingsApiProvider).update(row.key, value.trim());
      ref.invalidate(systemSettingsListProvider);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    // Watching the raw AsyncValue (not currentUserProvider, which collapses
    // "still loading" and "not logged in" to the same null) — on a hard
    // page reload, auth bootstrap is briefly in-flight, and a null role at
    // that point must NOT be treated as "role confirmed absent, fetch
    // anyway": that previously let this build call reach
    // ref.watch(systemSettingsListProvider) before the role was known,
    // firing the admin-only GET /api/settings for every role and bouncing
    // non-admins straight to Access Denied on reload.
    final authState = ref.watch(authControllerProvider);
    if (authState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final loginState = authState.valueOrNull;
    final role = loginState is LoginAuthenticated ? loginState.user.role : null;
    if (role != null && !_kSystemSettingsRoles.contains(role)) {
      return Center(
        child: Text(
          'Your role does not have access to System Settings.\nPermitted roles: ${_kSystemSettingsRoles.join(', ')}.',
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.ink2),
        ),
      );
    }

    final settingsAsync = ref.watch(systemSettingsListProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: error is ApiException ? error.message : '$error',
        onRetry: () => ref.invalidate(systemSettingsListProvider),
      ),
      data: (rows) {
        if (rows.isEmpty) return const EmptyState(message: 'No settings found.');
        return ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final row = rows[i];
            return Container(
              decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.key, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        if (row.description != null)
                          Text(row.description!, style: TextStyle(fontSize: 12, color: tokens.ink2)),
                      ],
                    ),
                  ),
                  if (_isBool(row.value))
                    Switch(value: row.value == 'true', onChanged: (_) => _toggle(context, ref, row))
                  else
                    OutlinedButton(
                      onPressed: () => _editValue(context, ref, row),
                      child: Text(row.value, style: const TextStyle(fontSize: 12.5)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab();

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  late final _fullNameController = TextEditingController(text: ref.read(currentUserProvider)?.fullName ?? '');
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _savingProfile = false;
  bool _changingPassword = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      await ref.read(usersApiProvider).updateProfile(
            fullName: _fullNameController.text.trim().isNotEmpty ? _fullNameController.text.trim() : null,
            phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 10 characters.')));
      return;
    }
    setState(() => _changingPassword = true);
    try {
      await ref.read(usersApiProvider).updatePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final user = ref.watch(currentUserProvider);

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your details', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            if (user != null) Text(user.email, style: TextStyle(fontSize: 12, color: tokens.ink2)),
            const SizedBox(height: 12),
            TextField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone number (optional)')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _savingProfile ? null : _saveProfile,
              child: _savingProfile
                  ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save profile'),
            ),
            const SizedBox(height: 28),
            Text('Change password', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            TextField(controller: _currentPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
            const SizedBox(height: 12),
            TextField(controller: _newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'New password (min. 10 characters)')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _changingPassword ? null : _changePassword,
              child: _changingPassword
                  ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Change password'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceTab extends ConsumerWidget {
  const _AppearanceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final role = ref.watch(currentUserProvider)?.role;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final option in const [
              (ThemeMode.system, 'Match system'),
              (ThemeMode.light, 'Light'),
              (ThemeMode.dark, 'Dark'),
            ])
              RadioListTile<ThemeMode>(
                value: option.$1,
                groupValue: mode,
                onChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v ?? ThemeMode.system),
                title: Text(option.$2),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            if (role == 'System Administrator') ...[
              const SizedBox(height: 28),
              const _BrandColorsSection(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pushes this deployment's brand colors up to docsecure-platform-provider
/// (System Administrator only, server-enforced too — see
/// backend/routes/settings.routes.js's PUT /theme) — the actual owner of
/// branding, so every other deployment licensed to this company and the
/// provider's own staff console stay in sync with whatever's set here.
class _BrandColorsSection extends ConsumerStatefulWidget {
  const _BrandColorsSection();

  @override
  ConsumerState<_BrandColorsSection> createState() => _BrandColorsSectionState();
}

class _BrandColorsSectionState extends ConsumerState<_BrandColorsSection> {
  late final _primaryController = TextEditingController();
  late final _secondaryController = TextEditingController();
  late final _accentController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _accentController.dispose();
    super.dispose();
  }

  void _seedFrom(CompanyBranding branding) {
    if (_initialized) return;
    _initialized = true;
    _primaryController.text = branding.primaryColor ?? '';
    _secondaryController.text = branding.secondaryColor ?? '';
    _accentController.text = branding.accentColor ?? '';
  }

  Future<void> _save() async {
    for (final controller in [_primaryController, _secondaryController, _accentController]) {
      final value = controller.text.trim();
      if (value.isNotEmpty && !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter colors as #RRGGBB, e.g. #0088B0.')));
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await ref.read(settingsApiProvider).updateTheme(
            primaryColor: _primaryController.text.trim().isEmpty ? null : _primaryController.text.trim(),
            secondaryColor: _secondaryController.text.trim().isEmpty ? null : _secondaryController.text.trim(),
            accentColor: _accentController.text.trim().isEmpty ? null : _accentController.text.trim(),
          );
      ref.invalidate(companyBrandingProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brand colors updated.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _colorField(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label, hintText: '#RRGGBB'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: parseHexColor(controller.text.trim()) ?? Colors.transparent,
            border: Border.all(color: context.tokens.line2),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(companyBrandingProvider).valueOrNull;
    if (branding != null) _seedFrom(branding);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Brand colors', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Applied across this deployment\'s buttons, focus states, and app bar accent — synced to DocSecure and any other deployment licensed to your organization.',
          style: TextStyle(fontSize: 12, color: context.tokens.ink2),
        ),
        const SizedBox(height: 12),
        _colorField('Primary color', _primaryController),
        const SizedBox(height: 12),
        _colorField('Secondary color', _secondaryController),
        const SizedBox(height: 12),
        _colorField('Accent color', _accentController),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save brand colors'),
        ),
      ],
    );
  }
}
