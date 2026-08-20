import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform_admin/platform_admin_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/pspf_tokens.dart';

/// Wraps every authenticated /platform-admin/* route. Intentionally
/// lightweight (no sidebar) — this module is a handful of screens, not a
/// full app shell like core/widgets/responsive_scaffold.dart.
class PlatformAdminShell extends ConsumerWidget {
  const PlatformAdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final admin = ref.watch(platformAdminAuthControllerProvider).valueOrNull;
    final atCompanies = GoRouterState.of(context).matchedLocation == RoutePaths.platformAdminCompanies;

    return Scaffold(
      backgroundColor: tokens.paper,
      appBar: AppBar(
        backgroundColor: tokens.bar,
        foregroundColor: tokens.barInk,
        leading: atCompanies
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(RoutePaths.platformAdminCompanies),
              ),
        title: const Text('DocSecore Platform Admin'),
        actions: [
          if (admin != null) Padding(padding: const EdgeInsets.only(right: 8), child: Center(child: Text(admin.fullName))),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(platformAdminAuthControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: child,
    );
  }
}
