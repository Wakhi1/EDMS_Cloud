import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/branding/branding_provider.dart';
import '../../../core/models/company_branding.dart';
import '../../../core/models/document_type_row.dart';
import '../../../core/models/record_index_row.dart';
import '../../../core/models/system_setting_row.dart';
import '../../../core/models/watermark_template_row.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/hex_color.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/result_dialog.dart';
import '../../../core/widgets/status_chip.dart';
import '../../repository/providers/repository_providers.dart';
import '../providers/record_index_providers.dart';
import '../providers/settings_providers.dart';
import '../providers/signature_providers.dart';
import '../providers/watermark_template_providers.dart';
import 'widgets/add_index_dialog.dart';
import 'widgets/add_watermark_template_dialog.dart';
import 'widgets/generate_indexes_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 6, vsync: this);

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
            tabs: const [
              Tab(text: 'System Settings'),
              Tab(text: 'Profile'),
              Tab(text: 'Appearance'),
              Tab(text: 'My Signature'),
              Tab(text: 'Indexing'),
              Tab(text: 'Watermarks'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_SystemSettingsTab(), _ProfileTab(), _AppearanceTab(), _SignatureTab(), _IndexingTab(), _WatermarksTab()],
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

  Future<void> _pickColor(TextEditingController controller) async {
    var picked = parseHexColor(controller.text.trim()) ?? context.tokens.acc;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: picked,
            onColorChanged: (c) => picked = c,
            enableAlpha: false,
            labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Select')),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => controller.text = toHexColor(picked));
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
        InkWell(
          onTap: () => _pickColor(controller),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: parseHexColor(controller.text.trim()) ?? Colors.transparent,
              border: Border.all(color: context.tokens.line2),
            ),
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

/// One saved signature per user, drawn or uploaded as a transparent PNG —
/// auto-attached when approving a workflow_steps.requires_signature step
/// (see approvals_screen.dart). Preview always goes through the app's own
/// Dio client (mySignatureImageBytesProvider), never Image.network — see
/// that provider's doc comment for why.
class _SignatureTab extends ConsumerStatefulWidget {
  const _SignatureTab();

  @override
  ConsumerState<_SignatureTab> createState() => _SignatureTabState();
}

enum _SignatureMode { draw, upload }

class _SignatureTabState extends ConsumerState<_SignatureTab> {
  _SignatureMode _mode = _SignatureMode.draw;
  late final _controller = SignatureController(penColor: Colors.black, exportBackgroundColor: Colors.transparent);
  Uint8List? _uploadedBytes;
  bool _saving = false;
  bool _deleting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickUpload() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['png']);
    if (result.isEmpty) return;
    final bytes = await result.first.readAsBytes();
    setState(() => _uploadedBytes = bytes);
  }

  Future<void> _save() async {
    final Uint8List? bytes;
    if (_mode == _SignatureMode.draw) {
      if (_controller.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draw a signature first.')));
        return;
      }
      bytes = await _controller.toPngBytes();
    } else {
      bytes = _uploadedBytes;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a PNG file first.')));
        return;
      }
    }
    if (bytes == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(signatureApiProvider).upload(bytes);
      ref.invalidate(mySignatureMetaProvider);
      ref.invalidate(mySignatureImageBytesProvider);
      _controller.clear();
      setState(() => _uploadedBytes = null);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signature saved.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await ref.read(signatureApiProvider).delete();
      ref.invalidate(mySignatureMetaProvider);
      ref.invalidate(mySignatureImageBytesProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signature removed.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final meta = ref.watch(mySignatureMetaProvider).valueOrNull;
    final imageBytes = ref.watch(mySignatureImageBytesProvider).valueOrNull;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My signature', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Used to auto-stamp your approval on workflow steps that require a signature.',
              style: TextStyle(fontSize: 12, color: tokens.ink2),
            ),
            const SizedBox(height: 16),
            if (meta?.hasSignature ?? false) ...[
              Text('Currently saved', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Container(
                height: 120,
                width: 240,
                decoration: BoxDecoration(border: Border.all(color: tokens.line), color: Colors.grey.shade100),
                alignment: Alignment.center,
                child: imageBytes != null
                    ? Image.memory(imageBytes, fit: BoxFit.contain)
                    : const CircularProgressIndicator(),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _deleting ? null : _delete,
                child: _deleting
                    ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Remove signature'),
              ),
              const SizedBox(height: 24),
            ],
            Text('Replace with a new signature', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            SegmentedButton<_SignatureMode>(
              segments: const [
                ButtonSegment(value: _SignatureMode.draw, label: Text('Draw')),
                ButtonSegment(value: _SignatureMode.upload, label: Text('Upload PNG')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 12),
            if (_mode == _SignatureMode.draw) ...[
              Container(
                height: 160,
                decoration: BoxDecoration(border: Border.all(color: tokens.line)),
                child: Signature(controller: _controller, backgroundColor: Colors.white),
              ),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () => _controller.clear(), child: const Text('Clear')),
            ] else ...[
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(border: Border.all(color: tokens.line), color: Colors.grey.shade100),
                alignment: Alignment.center,
                child: _uploadedBytes != null
                    ? Image.memory(_uploadedBytes!, fit: BoxFit.contain)
                    : Text('No file chosen', style: TextStyle(color: tokens.ink3)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _pickUpload, child: const Text('Choose PNG file')),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save signature'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Admin-managed record indexes (backend/routes/record-indexes.routes.js) —
/// "the way files are indexed should not be automatically done by the
/// system... should be done by following the already existing indexing
/// structures". Same client-side role gate as _SystemSettingsTab
/// (_kSystemSettingsRoles), and for the same reason: this tab is reachable
/// by every role via the shared Settings screen, so its API calls must not
/// fire before the signed-in role is confirmed to avoid a spurious 403
/// bouncing everyone to Access Denied.
class _IndexingTab extends ConsumerWidget {
  const _IndexingTab();

  Future<void> _generate(BuildContext context, WidgetRef ref, List<DocumentTypeRow> types) async {
    final result = await GenerateIndexesDialog.show(context, types: types);
    if (result == null) return;
    try {
      final values = await ref.read(recordIndexesApiProvider).generate(documentTypeId: result.documentTypeId, count: result.count);
      ref.invalidate(recordIndexListProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${values.length} indexes generated.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref, List<DocumentTypeRow> types) async {
    final result = await AddIndexDialog.show(context, types: types);
    if (result == null) return;
    try {
      await ref.read(recordIndexesApiProvider).create(documentTypeId: result.documentTypeId, indexValue: result.indexValue);
      ref.invalidate(recordIndexListProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Index added.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, RecordIndexRow row) async {
    final confirmed = await ConfirmDialog.show(context, title: 'Delete index "${row.indexValue}"?', danger: true, okLabel: 'Delete');
    if (confirmed == null) return;
    try {
      await ref.read(recordIndexesApiProvider).delete(row.id);
      ref.invalidate(recordIndexListProvider);
      if (context.mounted) await ResultDialog.showSuccess(context, 'Index deleted.');
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    final authState = ref.watch(authControllerProvider);
    if (authState.isLoading) return const Center(child: CircularProgressIndicator());
    final loginState = authState.valueOrNull;
    final role = loginState is LoginAuthenticated ? loginState.user.role : null;
    if (role != null && !_kSystemSettingsRoles.contains(role)) {
      return Center(
        child: Text(
          'Your role does not have access to Indexing.\nPermitted roles: ${_kSystemSettingsRoles.join(', ')}.',
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.ink2),
        ),
      );
    }

    final typesAsync = ref.watch(documentTypesProvider);
    final indexesAsync = ref.watch(recordIndexListProvider);
    final filters = ref.watch(recordIndexFiltersProvider);

    return typesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.bad)),
      data: (types) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record indexes', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Admin-issued index values. Uploads select from this list rather than the system generating a number.',
              style: TextStyle(fontSize: 12, color: tokens.ink2),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<int?>(
                    initialValue: filters.documentTypeId,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Type', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All types')),
                      for (final t in types) DropdownMenuItem(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => ref.read(recordIndexFiltersProvider.notifier).state = filters.copyWith(documentTypeId: () => v),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String?>(
                    initialValue: filters.status,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Status', isDense: true),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All statuses')),
                      DropdownMenuItem(value: 'available', child: Text('Available')),
                      DropdownMenuItem(value: 'used', child: Text('Used')),
                    ],
                    onChanged: (v) => ref.read(recordIndexFiltersProvider.notifier).state = filters.copyWith(status: () => v),
                  ),
                ),
                OutlinedButton(onPressed: () => _add(context, ref, types), child: const Text('Add index')),
                ElevatedButton(onPressed: () => _generate(context, ref, types), child: const Text('Generate indexes')),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: indexesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.bad)),
                data: (rows) {
                  if (rows.isEmpty) return const EmptyState(message: 'No record indexes yet — generate or add some above.');
                  return ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      return Container(
                        decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(row.indexValue, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(row.documentTypeName ?? '', style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: StatusChip(row.status ?? '', tone: row.status == 'used' ? StatusTone.plain : StatusTone.ok),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                row.usedByTitle != null ? 'Used by: ${row.usedByTitle}' : '—',
                                style: TextStyle(fontSize: 11.5, color: tokens.ink2),
                              ),
                            ),
                            if (row.status != 'used')
                              OutlinedButton(onPressed: () => _delete(context, ref, row), child: const Text('Delete')),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Admin-managed watermark text (backend/routes/watermark-templates.routes.js)
/// — "the way watermarks are set should be... admins in settings, with a
/// list to pick from," replacing the old per-user-identity stamp. Same
/// client-side role gate as _SystemSettingsTab/_IndexingTab
/// (_kSystemSettingsRoles) and the same reasoning: reachable by every role
/// via the shared Settings screen, so its API calls must not fire before
/// the signed-in role is confirmed.
class _WatermarksTab extends ConsumerWidget {
  const _WatermarksTab();

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String label, String text})>(context: context, builder: (_) => const AddWatermarkTemplateDialog());
    if (result == null) return;

    try {
      await ref.read(watermarkTemplatesApiProvider).create(label: result.label, text: result.text);
      ref.invalidate(watermarkTemplateListProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Watermark template created.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _setActive(BuildContext context, WidgetRef ref, WatermarkTemplateRow row) async {
    try {
      await ref.read(watermarkTemplatesApiProvider).setActive(row.id);
      ref.invalidate(activeWatermarkTemplateProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${row.label}" is now the active watermark.')));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, WatermarkTemplateRow row) async {
    final confirmed = await ConfirmDialog.show(context, title: 'Delete watermark template "${row.label}"?', danger: true, okLabel: 'Delete');
    if (confirmed == null) return;

    try {
      await ref.read(watermarkTemplatesApiProvider).delete(row.id);
      ref.invalidate(watermarkTemplateListProvider);
      if (context.mounted) await ResultDialog.showSuccess(context, 'Watermark template deleted.');
    } on ApiException catch (e) {
      if (context.mounted) await ResultDialog.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    final authState = ref.watch(authControllerProvider);
    if (authState.isLoading) return const Center(child: CircularProgressIndicator());
    final loginState = authState.valueOrNull;
    final role = loginState is LoginAuthenticated ? loginState.user.role : null;
    if (role != null && !_kSystemSettingsRoles.contains(role)) {
      return Center(
        child: Text(
          'Your role does not have access to Watermarks.\nPermitted roles: ${_kSystemSettingsRoles.join(', ')}.',
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.ink2),
        ),
      );
    }

    final templatesAsync = ref.watch(watermarkTemplateListProvider);
    final activeAsync = ref.watch(activeWatermarkTemplateProvider);
    final activeId = activeAsync.valueOrNull?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Watermark templates', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Stamped on every watermarked PDF download in place of the downloading user\'s name. Pick which one is active below.',
                    style: TextStyle(fontSize: 12, color: tokens.ink2),
                  ),
                ],
              ),
            ),
            ElevatedButton(onPressed: () => _add(context, ref), child: const Text('Add template')),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: templatesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(e is ApiException ? e.message : '$e', style: TextStyle(color: tokens.bad)),
            data: (rows) {
              if (rows.isEmpty) return const EmptyState(message: 'No watermark templates yet — add one above.');
              return ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final row = rows[i];
                  final isActive = row.id == activeId;
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: isActive ? tokens.acc : tokens.line),
                      color: tokens.surf,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(row.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  if (isActive) ...[
                                    const SizedBox(width: 8),
                                    StatusChip('active', tone: StatusTone.ok),
                                  ],
                                ],
                              ),
                              Text(row.text, style: TextStyle(fontSize: 11.5, color: tokens.ink2)),
                            ],
                          ),
                        ),
                        if (!isActive) ...[
                          OutlinedButton(onPressed: () => _setActive(context, ref, row), child: const Text('Set active')),
                          const SizedBox(width: 8),
                          OutlinedButton(onPressed: () => _delete(context, ref, row), child: const Text('Delete')),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
