import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/widgets/error_banner.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final user = ref.watch(currentUserProvider);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Security & Access / Authentication & Sessions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(PhosphorIconsDuotone.shieldCheck, size: 22, color: tokens.acc),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Signed in as ${user?.fullName ?? '—'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(user?.role ?? '—', style: TextStyle(fontSize: 12, color: tokens.ink2)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _AuthenticatorAppCard(),
            const SizedBox(height: 16),
            const _BackupCodesCard(),
          ],
        ),
      ),
    );
  }
}

class _AuthenticatorAppCard extends ConsumerStatefulWidget {
  const _AuthenticatorAppCard();

  @override
  ConsumerState<_AuthenticatorAppCard> createState() => _AuthenticatorAppCardState();
}

class _AuthenticatorAppCardState extends ConsumerState<_AuthenticatorAppCard> {
  bool _enrolling = false;
  bool _confirming = false;
  String? _qrDataUrl;
  String? _base32Secret;
  String? _error;
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _startEnroll() async {
    setState(() {
      _enrolling = true;
      _error = null;
    });
    try {
      final result = await ref.read(mfaApiProvider).totpEnroll();
      setState(() {
        _qrDataUrl = result.qrDataUrl;
        _base32Secret = result.base32Secret;
      });
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _enrolling = false);
    }
  }

  Future<void> _confirm() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _confirming = true;
      _error = null;
    });
    try {
      await ref.read(mfaApiProvider).totpConfirm(code);
      if (mounted) {
        setState(() {
          _qrDataUrl = null;
          _base32Secret = null;
          _codeController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authenticator app confirmed.')));
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _copyKey() {
    if (_base32Secret == null) return;
    Clipboard.setData(ClipboardData(text: _base32Secret!));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Key copied.')));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final isEnrolling = _qrDataUrl != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Authenticator app', style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Add or replace the authenticator app used for sign-in on this account.',
            style: TextStyle(fontSize: 12, color: tokens.ink2),
          ),
          const SizedBox(height: 12),
          if (!isEnrolling)
            OutlinedButton.icon(
              onPressed: _enrolling ? null : _startEnroll,
              icon: _enrolling
                  ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(PhosphorIconsDuotone.qrCode, size: 16),
              label: const Text('Set up authenticator app'),
            )
          else ...[
            Row(
              children: [
                Icon(PhosphorIconsDuotone.qrCode, size: 15, color: tokens.acc),
                const SizedBox(width: 6),
                Text('1. Scan this in your authenticator app', style: textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: Image.memory(
                  base64Decode(_qrDataUrl!.split(',').last),
                  width: 190,
                  height: 190,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text("Can't scan? Enter this key manually:", style: TextStyle(fontSize: 12, color: tokens.ink2)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(border: Border.all(color: tokens.line2), color: tokens.surf2),
                    child: Text(
                      _base32Secret ?? '',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13, letterSpacing: 1),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _copyKey,
                  icon: const Icon(Icons.copy, size: 17),
                  tooltip: 'Copy key',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(PhosphorIconsDuotone.checkCircle, size: 15, color: tokens.acc),
                const SizedBox(width: 6),
                Text('2. Enter the 6-digit code it shows', style: textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            if (_error != null) ...[
              ErrorBanner(_error!),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _codeController,
              enabled: !_confirming,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, letterSpacing: 5, fontWeight: FontWeight.w600),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '6-digit code'),
              onSubmitted: (_) => _confirm(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirming ? null : _confirm,
                child: _confirming
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('CONFIRM & ENABLE'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BackupCodesCard extends ConsumerStatefulWidget {
  const _BackupCodesCard();

  @override
  ConsumerState<_BackupCodesCard> createState() => _BackupCodesCardState();
}

class _BackupCodesCardState extends ConsumerState<_BackupCodesCard> {
  bool _generating = false;
  List<String>? _codes;

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final codes = await ref.read(mfaApiProvider).generateBackupCodes();
      setState(() => _codes = codes);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Backup codes', style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'One-time codes to use if you lose access to your authenticator app.',
            style: TextStyle(fontSize: 12, color: tokens.ink2),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(PhosphorIconsDuotone.key, size: 16),
            label: const Text('Generate new backup codes'),
          ),
          if (_codes != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: tokens.warn), color: tokens.surf2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Store these somewhere safe — they will not be shown again:',
                    style: TextStyle(fontSize: 12, color: tokens.warn, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      for (final code in _codes!)
                        Text(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
