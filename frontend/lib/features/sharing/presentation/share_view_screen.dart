import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/branding/branding_provider.dart';
import '../../../core/models/company_branding.dart';
import '../../../core/models/share_public_info.dart';
import '../../../core/theme/pspf_tokens.dart';
import '../../../core/utils/open_url/open_url.dart';
import '../../../core/widgets/company_logo_box.dart';

final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

/// Public, unauthenticated landing page for a shared-record link
/// (GET /api/sharing/public/:token) — the recipient has no EDMS account;
/// the token itself (unguessable, expiring, revocable) is the credential.
/// See core/router/app_router.dart's redirect allowlist for how this route
/// bypasses the normal login/activation gate, and
/// backend/routes/sharing.routes.js for the two endpoints this calls.
class ShareViewScreen extends ConsumerStatefulWidget {
  const ShareViewScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ShareViewScreen> createState() => _ShareViewScreenState();
}

class _ShareViewScreenState extends ConsumerState<ShareViewScreen> {
  late final Future<SharePublicInfo> _future = ref.read(sharingApiProvider).publicInfo(widget.token);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final branding = ref.watch(companyBrandingProvider).valueOrNull ?? CompanyBranding.fallback;

    return Scaffold(
      backgroundColor: tokens.paper,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CompanyLogoBox(size: 48),
                const SizedBox(height: 10),
                Text(branding.name, style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FutureBuilder<SharePublicInfo>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      final message = snapshot.error is ApiException ? (snapshot.error as ApiException).message : '${snapshot.error}';
                      return _MessageCard(icon: Icons.link_off, message: message, tokens: tokens);
                    }
                    final info = snapshot.data!;
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.insert_drive_file_outlined, size: 34, color: tokens.accD),
                          const SizedBox(height: 10),
                          Text(info.title, style: Theme.of(context).textTheme.titleSmall),
                          Text(info.recordNo, style: TextStyle(fontSize: 12, color: tokens.ink2)),
                          const SizedBox(height: 14),
                          Text('CLASSIFICATION', style: Theme.of(context).textTheme.labelSmall),
                          Text(info.classification, style: const TextStyle(fontSize: 12.5)),
                          const SizedBox(height: 10),
                          Text('LINK EXPIRES', style: Theme.of(context).textTheme.labelSmall),
                          Text(_dateTimeFormat.format(DateTime.parse(info.expiresAt).toLocal()), style: const TextStyle(fontSize: 12.5)),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => openUrlInNewTab(ref.read(sharingApiProvider).publicContentUrl(widget.token)),
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Download'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message, required this.tokens});

  final IconData icon;
  final String message;
  final PspfTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(border: Border.all(color: tokens.line), color: tokens.surf),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 34, color: tokens.ink3),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: tokens.ink2)),
        ],
      ),
    );
  }
}
