import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/module_access.dart';
import '../auth/module_access_events.dart';
import '../router/route_paths.dart';
import '../theme/pspf_tokens.dart';

/// Reached whenever the server returns 403 for a module (see
/// core/api/api_client.dart's onForbidden hook). A dedicated screen, not
/// just a silent redirect, matching the backend's own behaviour: every
/// denial is written to the audit trail server-side
/// (rbac.middleware.js), so telling the user that is accurate, not just
/// reassuring copy.
class AccessDeniedScreen extends ConsumerWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final message = ref.watch(lastDeniedMessageProvider) ?? 'This area is not available for your role.';
    final module = moduleFromDeniedMessage(message);
    final permittedRoles = module != null ? kModuleAllowedRoles[module] : null;

    return Scaffold(
      backgroundColor: tokens.paper,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tokens.surf,
              border: Border(
                top: BorderSide(color: tokens.bad, width: 3),
                left: BorderSide(color: tokens.line2),
                right: BorderSide(color: tokens.line2),
                bottom: BorderSide(color: tokens.line2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline, color: tokens.bad, size: 32),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Access denied', style: textTheme.titleLarge)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(message, style: textTheme.bodyMedium?.copyWith(color: tokens.ink2)),
                if (permittedRoles != null) ...[
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      style: textTheme.bodyMedium,
                      children: [
                        const TextSpan(text: 'Permitted roles: '),
                        TextSpan(text: permittedRoles.join(', '), style: TextStyle(color: tokens.ink)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  'This attempt has been written to the audit trail with your username, '
                  'IP address and the area requested.',
                  style: textTheme.bodySmall?.copyWith(color: tokens.ink2),
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: () => context.go(RoutePaths.dashboard),
                  child: const Text('Back to dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
